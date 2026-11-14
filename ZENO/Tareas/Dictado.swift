import Foundation
import Speech
import AVFoundation
import Observation

/// Convierte la voz en texto mientras la persona mantiene presionada a Lumi.
/// Solo usa el reconocimiento que funciona dentro del teléfono: la voz no sale del dispositivo.
@Observable
final class Dictado {
    var texto = ""
    var activo = false
    /// Mensaje amable cuando no se puede dictar (permisos, idioma, micrófono).
    var aviso: String?

    private let motor = AVAudioEngine()
    private let reconocedor = SFSpeechRecognizer()
    private var peticion: SFSpeechAudioBufferRecognitionRequest?
    private var reconocimiento: SFSpeechRecognitionTask?
    private var quiereEscuchar = false

    func empezar() {
        aviso = nil
        texto = ""
        quiereEscuchar = true

        let vozLista = SFSpeechRecognizer.authorizationStatus() == .authorized
        let microLista = AVAudioApplication.shared.recordPermission == .granted
        if vozLista && microLista {
            iniciar()
            return
        }

        // La primera vez iOS pregunta; después de aceptar hay que volver a presionar.
        quiereEscuchar = false
        SFSpeechRecognizer.requestAuthorization { estado in
            AVAudioApplication.requestRecordPermission { micro in
                DispatchQueue.main.async {
                    if estado == .authorized && micro {
                        self.aviso = Idioma.texto("Listo. Mantén presionada a Lumi y habla.")
                    } else {
                        self.aviso = Idioma.texto("Para hablarle a Lumi, activa el micrófono y el dictado en Ajustes. También puedes escribir.")
                    }
                }
            }
        }
    }

    func detener() {
        quiereEscuchar = false
        guard activo else { return }
        motor.stop()
        motor.inputNode.removeTap(onBus: 0)
        peticion?.endAudio()
        reconocimiento?.finish()
        peticion = nil
        reconocimiento = nil
        activo = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func iniciar() {
        guard let reconocedor, reconocedor.isAvailable else {
            aviso = Idioma.texto("El dictado no está disponible ahora. Puedes escribir.")
            return
        }
        // Privacidad: solo dictado dentro del teléfono.
        guard reconocedor.supportsOnDeviceRecognition else {
            aviso = Idioma.texto("Este teléfono no puede dictar en tu idioma sin enviar tu voz fuera. Puedes escribir.")
            return
        }

        do {
            let sesion = AVAudioSession.sharedInstance()
            try sesion.setCategory(.record, mode: .measurement, options: .duckOthers)
            try sesion.setActive(true, options: .notifyOthersOnDeactivation)

            let entrada = motor.inputNode
            let formato = entrada.outputFormat(forBus: 0)
            guard formato.sampleRate > 0, formato.channelCount > 0 else {
                aviso = Idioma.texto("No encuentro un micrófono. Puedes escribir.")
                return
            }

            let peticion = SFSpeechAudioBufferRecognitionRequest()
            peticion.shouldReportPartialResults = true
            peticion.requiresOnDeviceRecognition = true
            self.peticion = peticion

            entrada.removeTap(onBus: 0)
            entrada.installTap(onBus: 0, bufferSize: 1024, format: formato) { bufer, _ in
                peticion.append(bufer)
            }
            motor.prepare()
            try motor.start()
            activo = true

            reconocimiento = reconocedor.recognitionTask(with: peticion) { [weak self] resultado, _ in
                guard let resultado else { return }
                let frase = resultado.bestTranscription.formattedString
                DispatchQueue.main.async { self?.texto = frase }
            }
        } catch {
            aviso = Idioma.texto("No pude escucharte esta vez. Puedes escribir.")
            detener()
        }
    }
}
