package io.luma.tv

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.os.storage.StorageManager
import android.os.storage.StorageVolume
import android.provider.DocumentsContract
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "luma/storage"
        private const val REQUEST_PICK_FOLDER = 4101
        private const val REQUEST_READ_STORAGE = 4102
        private const val REQUEST_STORAGE_PERMISSION = 4103
        private const val TAG = "Luma/Storage"
    }

    private var pendingPick: MethodChannel.Result? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasAllFilesAccess" -> result.success(hasAllFilesAccess())
                    "requestAllFilesAccess" -> {
                        val status = requestAllFilesAccess()
                        Log.i(TAG, "requestAllFilesAccess -> $status")
                        result.success(status)
                    }
                    "pickFolder" -> pickFolder(result)
                    "requestStoragePermission" -> {
                        pendingPermissionResult = result
                        val status = requestStoragePermission()
                        if (status != "runtime_requested") {
                            pendingPermissionResult = null
                            result.success(status)
                        }
                        // 若是 runtime_requested，等 onRequestPermissionsResult 回调再返回
                    }
                    "getStorageVolumes" -> result.success(storageVolumes())
                    "openAppSettings" -> {
                        openAppSettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasAllFilesAccess(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (Environment.isExternalStorageManager()) return true
            return checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) ==
                PackageManager.PERMISSION_GRANTED ||
                checkSelfPermission(Manifest.permission.READ_MEDIA_VIDEO) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            return checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) ==
                PackageManager.PERMISSION_GRANTED
        }
    }

    /**
     * Opens the closest screen this device exposes for granting All-Files-Access.
     * Returns a status the UI can show, so failures are never silent.
     */
    private fun requestAllFilesAccess(): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (Environment.isExternalStorageManager()) return "already_granted"

            val appIntent = Intent(
                Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
            ).apply { data = Uri.parse("package:$packageName") }
            if (startActivityIfAvailable(appIntent)) return "opened_manage_app"

            val listIntent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
            if (startActivityIfAvailable(listIntent)) return "opened_manage_all"

            val detailsIntent = Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:$packageName"),
            )
            if (startActivityIfAvailable(detailsIntent)) return "opened_app_details"

            Log.w(TAG, "No settings screen for MANAGE_EXTERNAL_STORAGE on this device")
            return "unsupported"
        } else {
            if (checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                requestPermissions(
                    arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE),
                    REQUEST_READ_STORAGE,
                )
            }
            return "runtime_requested"
        }
    }

    /**
     * 请求普通运行时存储权限（READ_EXTERNAL_STORAGE / READ_MEDIA_VIDEO）。
     * 这会弹出系统标准对话框，用户点“允许”即可，不需要去设置页翻找
     * “所有文件访问权限”。适合 Android TV 等无法打开 MANAGE_EXTERNAL_STORAGE
     * 设置页的设备。
     */
    private fun requestStoragePermission(): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (hasAllFilesAccess()) return "already_granted"

            val perms = mutableListOf<String>()
            if (checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                perms.add(Manifest.permission.READ_EXTERNAL_STORAGE)
            }
            if (checkSelfPermission(Manifest.permission.READ_MEDIA_VIDEO) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                perms.add(Manifest.permission.READ_MEDIA_VIDEO)
            }
            if (perms.isEmpty()) return "already_granted"

            requestPermissions(perms.toTypedArray(), REQUEST_STORAGE_PERMISSION)
            return "runtime_requested"
        } else {
            if (checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) ==
                PackageManager.PERMISSION_GRANTED
            ) {
                return "already_granted"
            }
            requestPermissions(
                arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE),
                REQUEST_STORAGE_PERMISSION,
            )
            return "runtime_requested"
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        val result = pendingPermissionResult ?: return
        pendingPermissionResult = null
        val granted = grantResults.isNotEmpty() && grantResults[0] ==
            PackageManager.PERMISSION_GRANTED
        result.success(if (granted) "granted" else "denied")
    }

    private fun startActivityIfAvailable(intent: Intent): Boolean {
        return try {
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                true
            } else {
                Log.i(TAG, "Activity not available for intent: ${intent.action}")
                false
            }
        } catch (error: Exception) {
            Log.w(TAG, "Failed to start ${intent.action}: ${error.message}")
            false
        }
    }

    private fun pickFolder(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("busy", "另一个目录选择器正在打开", null)
            return
        }
        pendingPick = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
        }
        try {
            startActivityForResult(intent, REQUEST_PICK_FOLDER)
        } catch (error: Exception) {
            pendingPick = null
            result.error("picker_unavailable", "此设备没有可用的文件选择器", error.message)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_PICK_FOLDER) return
        val result = pendingPick ?: return
        pendingPick = null

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }

        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        } catch (_: SecurityException) {
            // Some document providers do not support persistable grants.
        }

        val path = treeUriToPath(uri)
        val file = path?.let { File(it) }
        val accessible = file != null && file.exists() && file.canRead()
        result.success(
            mapOf(
                "path" to path,
                "uri" to uri.toString(),
                "name" to treeDisplayName(uri),
                "accessible" to accessible,
            ),
        )
    }

    /**
     * Converts a SAF tree uri into a real filesystem path. External storage
     * document ids look like "primary:Movies" or "1234-ABCD:Shows".
     */
    private fun treeUriToPath(uri: Uri): String? {
        if (uri.authority != "com.android.externalstorage.documents") return null
        val documentId = try {
            DocumentsContract.getTreeDocumentId(uri)
        } catch (_: Exception) {
            return null
        }
        val parts = documentId.split(":", limit = 2)
        val volume = parts[0]
        val relative = if (parts.size > 1) parts[1].trim('/') else ""
        val root = if (volume.equals("primary", ignoreCase = true)) {
            Environment.getExternalStorageDirectory().absolutePath
        } else {
            "/storage/$volume"
        }
        return if (relative.isEmpty()) root else "$root/$relative"
    }

    private fun treeDisplayName(uri: Uri): String {
        val documentId = try {
            DocumentsContract.getTreeDocumentId(uri)
        } catch (_: Exception) {
            ""
        }
        return try {
            val documentUri = DocumentsContract.buildDocumentUriUsingTree(uri, documentId)
            contentResolver.query(
                documentUri,
                arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
                null,
                null,
                null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val name = cursor.getString(0)
                    if (!name.isNullOrBlank()) return name
                }
            }
            documentId.substringAfterLast(':').substringAfterLast('/')
                .ifBlank { "媒体目录" }
        } catch (_: Exception) {
            documentId.ifBlank { "媒体目录" }
        }
    }

    private fun storageVolumes(): List<Map<String, Any>> {
        val manager = getSystemService(STORAGE_SERVICE) as StorageManager
        val seen = mutableSetOf<String>()
        val result = mutableListOf<Map<String, Any>>()

        for (volume in manager.storageVolumes) {
            val state = volume.state
            if (state != Environment.MEDIA_MOUNTED &&
                state != Environment.MEDIA_MOUNTED_READ_ONLY
            ) {
                continue
            }
            val directory = volumeDirectory(volume) ?: continue
            if (!directory.exists()) continue
            // 注意：不要在这里用 directory.canRead() 过滤。
            // Android 11+ 未授予“所有文件访问权限”时，外接磁盘的
            // /storage/XXXX-XXXX 目录 canRead() 为 false，但磁盘本身
            // 是存在且可挂载的。过滤掉会导致“添加目录”里看不到 U 盘。
            // 读取失败交给 Dart 侧提示用户去授权。
            val path = directory.absolutePath
            if (!seen.add(path)) continue
            val stats = try {
                StatFs(path)
            } catch (_: Exception) {
                null
            }
            val total = stats?.let { it.blockCountLong * it.blockSizeLong } ?: 0L
            val free = stats?.let { it.availableBlocksLong * it.blockSizeLong } ?: 0L
            result.add(
                mapOf(
                    "path" to path,
                    "label" to (volume.getDescription(this) ?: directory.name),
                    "removable" to volume.isRemovable,
                    "totalBytes" to total,
                    "freeBytes" to free,
                ),
            )
        }

        // 部分 Android TV 固件的 StorageManager 不会列出 U 盘，
        // 这里补扫 /storage 下的挂载点，避免“添加目录”里看不到外接磁盘。
        val storageRoot = File("/storage")
        if (storageRoot.isDirectory) {
            storageRoot.listFiles()?.forEach { dir ->
                val name = dir.name
                if (!dir.isDirectory || !dir.exists()) return@forEach
                if (name == "emulated" || name == "self") return@forEach
                val path = dir.absolutePath
                if (!seen.add(path)) return@forEach
                val stats = try {
                    StatFs(path)
                } catch (_: Exception) {
                    null
                }
                result.add(
                    mapOf(
                        "path" to path,
                        "label" to name,
                        "removable" to true,
                        "totalBytes" to (stats?.let { it.blockCountLong * it.blockSizeLong } ?: 0L),
                        "freeBytes" to (stats?.let { it.availableBlocksLong * it.blockSizeLong } ?: 0L),
                    ),
                )
            }
        }

        // Older firmware occasionally reports no volumes. Fall back to the
        // conventional shared-storage mount so users can still add a folder.
        if (result.isEmpty()) {
            val fallback = Environment.getExternalStorageDirectory()
            if (fallback.exists()) {
                val stats = try {
                    StatFs(fallback.absolutePath)
                } catch (_: Exception) {
                    null
                }
                result.add(
                    mapOf(
                        "path" to fallback.absolutePath,
                        "label" to "内部存储",
                        "removable" to false,
                        "totalBytes" to (stats?.let { it.blockCountLong * it.blockSizeLong } ?: 0L),
                        "freeBytes" to (stats?.let { it.availableBlocksLong * it.blockSizeLong } ?: 0L),
                    ),
                )
            }
        }

        result.sortWith(compareByDescending<Map<String, Any>> { it["removable"] as Boolean }
            .thenBy { it["label"] as String })
        return result
    }

    @Suppress("DEPRECATION")
    private fun volumeDirectory(volume: StorageVolume): File? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            return volume.directory
        }
        return try {
            val file = StorageVolume::class.java.getMethod("getPathFile")
                .invoke(volume) as? File
            val path = StorageVolume::class.java.getMethod("getPath")
                .invoke(volume) as? String
            file ?: path?.let { File(it) }
        } catch (_: Exception) {
            null
        }
    }

    private fun openAppSettings() {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:$packageName"),
        )
        try {
            startActivity(intent)
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_SETTINGS))
            } catch (_: Exception) {
                // Ignore.
            }
        }
    }
}
