package com.tricognia.speech

import android.Manifest
import android.content.pm.PackageManager
import android.media.MediaRecorder
import android.os.Build
import android.util.Base64
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import java.io.File

/**
 * SpeechPlugin — Godot v2 Android plugin.
 * Records audio via MediaRecorder (VOICE_RECOGNITION source, AAC/M4A).
 * Transcription is handled server-side by the backend (Groq Whisper).
 *
 * Signals emitted to GDScript:
 *   recording_completed(audio_base64: String)
 *   recording_error(reason: String)
 *   listening_started()
 *   listening_ended()
 */
class SpeechPlugin(godot: Godot) : GodotPlugin(godot) {

    companion object {
        private const val PERMISSION_REQUEST_CODE = 9001
    }

    override fun getPluginName(): String = "SpeechPlugin"

    override fun getPluginSignals(): MutableSet<SignalInfo> = mutableSetOf(
        SignalInfo("recording_completed", String::class.java),
        SignalInfo("recording_error", String::class.java),
        SignalInfo("listening_started"),
        SignalInfo("listening_ended"),
    )

    private var mediaRecorder: MediaRecorder? = null
    private var audioFilePath: String = ""
    private var pendingLanguage: String? = null

    // ── Public API (exposed to GDScript via @UsedByGodot) ──────────────────

    @UsedByGodot
    fun isAvailable(): Boolean {
        activity ?: return false
        return true
    }

    @UsedByGodot
    fun startRecording(language: String) {
        val activity = activity ?: run {
            emitSignal("recording_error", "Activity not available.")
            return
        }

        // Check RECORD_AUDIO permission
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            pendingLanguage = language
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                PERMISSION_REQUEST_CODE
            )
            return
        }

        activity.runOnUiThread { startRecordingInternal() }
    }

    @UsedByGodot
    fun stopRecording() {
        // Stop MediaRecorder with Bluetooth-disconnect protection
        try {
            mediaRecorder?.stop()
        } catch (_: RuntimeException) {
            // -1007 = stop failed (Bluetooth disconnect, audio route change).
            // Partial file may still be usable.
        }
        try {
            mediaRecorder?.release()
        } catch (_: Exception) {}
        mediaRecorder = null

        emitSignal("listening_ended")

        // Emit recorded audio as base64
        val file = File(audioFilePath)
        if (file.exists() && file.length() > 0) {
            val bytes = file.readBytes()
            val b64 = Base64.encodeToString(bytes, Base64.NO_WRAP)
            emitSignal("recording_completed", b64)
        } else {
            emitSignal("recording_completed", "")
        }
    }

    @UsedByGodot
    fun getAudioBase64(): String {
        if (audioFilePath.isEmpty()) return ""
        val file = File(audioFilePath)
        if (!file.exists()) return ""
        return Base64.encodeToString(file.readBytes(), Base64.NO_WRAP)
    }

    // ── Internal ───────────────────────────────────────────────────────────

    private fun startRecordingInternal() {
        val activity = activity ?: return

        // Generate temp file path in app cache (scoped-storage safe)
        audioFilePath = File(
            activity.cacheDir,
            "speech_${System.currentTimeMillis()}.m4a"
        ).absolutePath

        try {
            @Suppress("DEPRECATION")
            val recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(activity)
            } else {
                MediaRecorder()
            }
            recorder.apply {
                setAudioSource(MediaRecorder.AudioSource.VOICE_RECOGNITION)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setAudioSamplingRate(44100)
                setAudioEncodingBitRate(128000)
                setOutputFile(audioFilePath)
                prepare()
                start()
            }
            mediaRecorder = recorder
        } catch (e: Exception) {
            emitSignal("recording_error", "Could not start audio recording: ${e.message}")
            return
        }

        emitSignal("listening_started")
    }

    // Handle permission result
    override fun onMainRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                pendingLanguage?.let { startRecording(it) }
            } else {
                emitSignal("recording_error", "Microphone permission denied.")
            }
            pendingLanguage = null
        }
    }
}
