package com.tricognia.speech

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaRecorder
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Base64
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import org.json.JSONArray
import java.io.File

/**
 * SpeechPlugin — Godot v2 Android plugin.
 * Runs MediaRecorder (saves audio) + SpeechRecognizer (transcribes)
 * simultaneously using Android 10+ shared mic support.
 *
 * Signals emitted to GDScript:
 *   transcript_ready(text: String, confidence: Float, alternatives_json: String)
 *   recording_completed(audio_base64: String)
 *   recognition_error(reason: String)
 *   recognition_unavailable()
 *   listening_started()
 *   listening_ended()
 */
class SpeechPlugin(godot: Godot) : GodotPlugin(godot) {

    companion object {
        private const val PERMISSION_REQUEST_CODE = 9001
    }

    override fun getPluginName(): String = "SpeechPlugin"

    override fun getPluginSignals(): MutableSet<SignalInfo> = mutableSetOf(
        SignalInfo("transcript_ready", String::class.java, java.lang.Float::class.java, String::class.java),
        SignalInfo("recording_completed", String::class.java),
        SignalInfo("recognition_error", String::class.java),
        SignalInfo("recognition_unavailable"),
        SignalInfo("listening_started"),
        SignalInfo("listening_ended"),
    )

    private var mediaRecorder: MediaRecorder? = null
    private var speechRecognizer: SpeechRecognizer? = null
    private var audioFilePath: String = ""
    private var currentLanguage: String = "en-US"
    private var pendingLanguage: String? = null
    private var isListening: Boolean = false

    // ── Public API (exposed to GDScript via @UsedByGodot) ──────────────────

    @UsedByGodot
    fun isAvailable(): Boolean {
        val activity = activity ?: return false
        return SpeechRecognizer.isRecognitionAvailable(activity)
    }

    @UsedByGodot
    fun startRecording(language: String) {
        val activity = activity ?: run {
            emitSignal("recognition_unavailable")
            return
        }

        currentLanguage = language

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
        // Stop MediaRecorder
        try {
            mediaRecorder?.apply { stop(); release() }
        } catch (e: Exception) {
            // MediaRecorder may throw if stopped too quickly
        }
        mediaRecorder = null

        // Stop SpeechRecognizer on Android UI main thread
        val act = activity
        if (act != null) {
            act.runOnUiThread {
                try { speechRecognizer?.stopListening() } catch (_: Exception) {}
                isListening = false
            }
        } else {
            isListening = false
        }

        emitSignal("listening_ended")

        // Emit recorded audio as base64
        val file = File(audioFilePath)
        if (file.exists() && file.length() > 0) {
            val bytes = file.readBytes()
            val b64 = Base64.encodeToString(bytes, Base64.NO_WRAP)
            emitSignal("recording_completed", b64)
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

        // Generate temp file path
        audioFilePath = File(
            activity.cacheDir,
            "speech_${System.currentTimeMillis()}.m4a"
        ).absolutePath

        // 1. Start MediaRecorder (saves audio file)
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
            emitSignal("recognition_error", "Could not start audio recording: ${e.message}")
            return
        }

        // 2. Start SpeechRecognizer (already on main thread — caller ensures runOnUiThread)
        try {
            // Destroy any stale instance before creating a new one
            speechRecognizer?.destroy()
            speechRecognizer = null

            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(activity)
            if (speechRecognizer == null) {
                emitSignal("recognition_error", "Speech recognizer service unavailable on this device.")
                return
            }
            speechRecognizer?.setRecognitionListener(recognitionListener)

            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, currentLanguage)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
            }
            speechRecognizer?.startListening(intent)
            isListening = true
        } catch (e: Exception) {
            emitSignal("recognition_error", "Could not start speech recognizer: ${e.message}")
            return
        }
        emitSignal("listening_started")
    }

    private val recognitionListener = object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {}
        override fun onBeginningOfSpeech() {}
        override fun onRmsChanged(rmsdB: Float) {}
        override fun onBufferReceived(buffer: ByteArray?) {}
        override fun onEndOfSpeech() {}

        override fun onError(error: Int) {
            isListening = false
            val msg = when (error) {
                SpeechRecognizer.ERROR_AUDIO -> "Audio recording error."
                SpeechRecognizer.ERROR_NO_MATCH -> "No speech detected. Please speak clearly and try again."
                SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech detected. Please try again."
                SpeechRecognizer.ERROR_NETWORK -> "Network error. Please check your connection."
                SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout. Please try again."
                SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Microphone permission denied."
                SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Speech recognizer is busy. Try again."
                SpeechRecognizer.ERROR_CLIENT -> "Client error."
                else -> "Speech recognition error (code: $error)."
            }
            emitSignal("recognition_error", msg)
            cleanupRecognizer()
        }

        override fun onResults(results: Bundle?) {
            isListening = false
            val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            val confidences = results?.getFloatArray(SpeechRecognizer.CONFIDENCE_SCORES)

            if (matches.isNullOrEmpty()) {
                emitSignal("recognition_error", "No speech detected. Please speak clearly and try again.")
                cleanupRecognizer()
                return
            }

            val bestText = matches[0]
            val bestConfidence = confidences?.getOrNull(0) ?: 0.85f

            // Build JSON array of all alternatives
            val altArray = JSONArray()
            for (m in matches) {
                altArray.put(m)
            }

            emitSignal("transcript_ready", bestText, bestConfidence, altArray.toString())
            cleanupRecognizer()
        }

        override fun onPartialResults(partialResults: Bundle?) {}
        override fun onEvent(eventType: Int, params: Bundle?) {}
    }

    private fun cleanupRecognizer() {
        val act = activity
        val recognizer = speechRecognizer
        speechRecognizer = null
        if (act != null && recognizer != null) {
            act.runOnUiThread {
                try { recognizer.destroy() } catch (_: Exception) {}
            }
        }
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
                emitSignal("recognition_error", "Microphone permission denied.")
            }
            pendingLanguage = null
        }
    }
}
