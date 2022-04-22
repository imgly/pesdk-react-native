package ly.img.react_native.pesdk

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.util.Log
import com.facebook.react.bridge.*
import ly.img.android.IMGLY
import ly.img.android.PESDK
import ly.img.android.pesdk.PhotoEditorSettingsList
import ly.img.android.pesdk.backend.decoder.ImageSource
import ly.img.android.pesdk.backend.model.state.LoadSettings
import ly.img.android.pesdk.backend.model.state.manager.SettingsList
import ly.img.android.pesdk.kotlin_extension.continueWithExceptions
import ly.img.android.pesdk.ui.activity.PhotoEditorBuilder
import ly.img.android.pesdk.utils.MainThreadRunnable
import ly.img.android.pesdk.utils.SequenceRunnable
import ly.img.android.pesdk.utils.UriHelper
import ly.img.android.sdk.config.*
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.io.File
import ly.img.android.pesdk.backend.encoder.Encoder
import ly.img.android.pesdk.backend.model.EditorSDKResult
import ly.img.android.serializer._3.IMGLYFileReader
import ly.img.android.serializer._3.IMGLYFileWriter
import java.util.UUID

class RNPhotoEditorSDKModule(val reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext), ActivityEventListener {

    companion object {
        // This number must be unique. It is public to allow client code to change it if the same value is used elsewhere.
        var EDITOR_RESULT_ID = 29064
    }

    init {
        reactContext.addActivityEventListener(this)

    }

    private var currentPromise: Promise? = null
    private var currentConfig: Configuration? = null

    @ReactMethod
    fun unlockWithLicense(license: String) {
        PESDK.initSDKWithLicenseData(license)
        IMGLY.authorize()
    }

    override fun onActivityResult(activity: Activity, requestCode: Int, resultCode: Int, intent: Intent?) {
        val data = try {
          intent?.let { EditorSDKResult(it) }
        } catch (e: EditorSDKResult.NotAnImglyResultException) {
          null
        } ?: return // If data is null the result is not from us.

        when (requestCode) {
            EDITOR_RESULT_ID -> {
                when (resultCode) {
                    Activity.RESULT_CANCELED -> {
                        currentPromise?.resolve(null)
                    }
                    Activity.RESULT_OK -> {
                        SequenceRunnable("Export Done") {
                            val sourcePath = data.sourceUri
                            val resultPath = data.resultUri

                            val serializationConfig = currentConfig?.export?.serialization

                            var serialization: Any? = null
                            if (serializationConfig?.enabled == true) {
                                val settingsList = data.settingsList
                                skipIfNotExists {
                                    settingsList.let { settingsList ->
                                        if (serializationConfig.embedSourceImage == true) {
                                            Log.i("ImgLySdk", "EmbedSourceImage is currently not supported by the Android SDK")
                                        }
                                        serialization = when (serializationConfig.exportType) {
                                            SerializationExportType.FILE_URL -> {
                                                val uri = serializationConfig.filename?.let {
                                                    Uri.parse("$it.json")
                                                } ?: Uri.fromFile(File.createTempFile("serialization-" + UUID.randomUUID().toString(), ".json"))
                                                Encoder.createOutputStream(uri).use { outputStream -> 
                                                    IMGLYFileWriter(settingsList).writeJson(outputStream)
                                                }
                                                uri.toString()
                                            }
                                            SerializationExportType.OBJECT -> {
                                                ReactJSON.convertJsonToMap(
                                                  JSONObject(
                                                          IMGLYFileWriter(settingsList).writeJsonAsString()
                                                  )
                                                )
                                            }
                                        }
                                    }
                                    settingsList.release()
                                } ?: run {
                                    Log.i("ImgLySdk", "You need to include 'backend:serializer' Module, to use serialisation!")
                                }
                            }

                            currentPromise?.resolve(
                              reactMap(
                                "image" to when (currentConfig?.export?.image?.exportType) {
                                    ImageExportType.DATA_URL -> resultPath?.let {
                                        val imageSource = ImageSource.create(it)
                                        "data:${imageSource.imageFormat.mimeType};base64,${imageSource.asBase64}"
                                    }
                                    ImageExportType.FILE_URL -> resultPath?.toString()
                                    else -> resultPath?.toString()
                                },
                                "hasChanges" to (sourcePath?.path != resultPath?.path),
                                "serialization" to serialization
                              )
                            )
                        }()
                    }
                }
            }
        }
    }


    override fun onNewIntent(intent: Intent?) {
    }

    @ReactMethod
    fun present(image: String?, config: ReadableMap?, serialization: String?, promise: Promise) {
        IMGLY.authorize()

        val configuration = ConfigLoader.readFrom(config?.toHashMap() ?: mapOf())
        val settingsList = PhotoEditorSettingsList(configuration.export?.serialization?.enabled == true)
        configuration.applyOn(settingsList)
        currentConfig = configuration
        currentPromise = promise

        settingsList.configure<LoadSettings> { loadSettings ->
            image?.also {
                if (it.startsWith("data:")) {
                    loadSettings.source = UriHelper.createFromBase64String(it.substringAfter("base64,"))
                } else {
                    val potentialFile = continueWithExceptions { File(it) }
                    if (potentialFile?.exists() == true) {
                        loadSettings.source = Uri.fromFile(potentialFile)
                    } else {
                        loadSettings.source = ConfigLoader.parseUri(it)
                    }
                }
            }
        }

        readSerialisation(settingsList, serialization, image == null)

        startEditor(settingsList)
    }

    private fun readSerialisation(settingsList: SettingsList, serialization: String?, readImage: Boolean) {
        if (serialization != null) {
            skipIfNotExists {
                IMGLYFileReader(settingsList).also {
                    it.readJson(serialization, readImage)
                }
            }
        }
    }

    private fun startEditor(settingsList: PhotoEditorSettingsList?) {
        val currentActivity = this.currentActivity ?: throw RuntimeException("Can't start the Editor because there is no current activity")
        if (settingsList != null) {
            MainThreadRunnable {
                PhotoEditorBuilder(currentActivity)
                  .setSettingsList(settingsList)
                  .startActivityForResult(currentActivity, EDITOR_RESULT_ID)
                settingsList.release()
            }()
        }
    }

    operator fun WritableMap.set(id: String, value: Boolean) = this.putBoolean(id, value)
    operator fun WritableMap.set(id: String, value: String?) = this.putString(id, value)
    operator fun WritableMap.set(id: String, value: Double) = this.putDouble(id, value)
    operator fun WritableMap.set(id: String, value: Float) = this.putDouble(id, value.toDouble())
    operator fun WritableMap.set(id: String, value: WritableArray?) = this.putArray(id, value)
    operator fun WritableMap.set(id: String, value: Int) = this.putInt(id, value)
    operator fun WritableMap.set(id: String, value: WritableMap?) = this.putMap(id, value)

    fun reactMap(vararg pairs: Pair<String, Any?>): WritableMap {
        val map = Arguments.createMap()

        for (pair in pairs) {
            val id = pair.first
            when (val value = pair.second) {
                is String? -> map[id] = value
                is Boolean -> map[id] = value
                is Double -> map[id] = value
                is Float -> map[id] = value
                is Int -> map[id] = value
                is WritableMap? -> map[id] = value
                is WritableArray? -> map[id] = value
                else -> if (value == null) {
                    map.putNull(id)
                } else {
                    throw RuntimeException("Type not supported by WritableMap")
                }
            }
        }

        return map
    }


    object ReactJSON {
        @Throws(JSONException::class) fun convertJsonToMap(jsonObject: JSONObject): WritableMap? {
            val map: WritableMap = WritableNativeMap()
            val iterator: Iterator<String> = jsonObject.keys()
            while (iterator.hasNext()) {
                val key = iterator.next()
                val value: Any = jsonObject.get(key)
                when (value) {
                    is JSONObject -> {
                        map.putMap(key, convertJsonToMap(value))
                    }
                    is JSONArray -> {
                        map.putArray(key, convertJsonToArray(value))
                    }
                    is Boolean -> {
                        map.putBoolean(key, value)
                    }
                    is Int -> {
                        map.putInt(key, value)
                    }
                    is Double -> {
                        map.putDouble(key, value)
                    }
                    is String -> {
                        map.putString(key, value)
                    }
                    else -> {
                        map.putString(key, value.toString())
                    }
                }
            }
            return map
        }

        @Throws(JSONException::class) fun convertJsonToArray(jsonArray: JSONArray): WritableArray? {
            val array: WritableArray = WritableNativeArray()
            for (i in 0 until jsonArray.length()) {
                when (val value: Any = jsonArray.get(i)) {
                    is JSONObject -> {
                        array.pushMap(convertJsonToMap(value))
                    }
                    is JSONArray -> {
                        array.pushArray(convertJsonToArray(value))
                    }
                    is Boolean -> {
                        array.pushBoolean(value)
                    }
                    is Int -> {
                        array.pushInt(value)
                    }
                    is Double -> {
                        array.pushDouble(value)
                    }
                    is String -> {
                        array.pushString(value)
                    }
                    else -> {
                        array.pushString(value.toString())
                    }
                }
            }
            return array
        }
    }

    override fun getName() = "RNPhotoEditorSDK"

}