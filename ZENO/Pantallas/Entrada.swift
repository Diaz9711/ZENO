import SwiftUI
import AuthenticationServices

// MARK: - Menú de entrada

/// La entrada a ZENO, con estilo de lujo. Sin servidor: todo vive en el teléfono.
/// - La primera vez: Apple, invitado, o crear una clave local.
/// - Al volver tras cerrar sesión: si hay clave, se pide la clave (o Face ID); si no, Apple o invitado.
struct MenuDeEntrada: View {
    /// La persona ya existe (vuelve tras cerrar sesión).
    var vuelve = false
    let alEntrar: () -> Void
    let alApple: ((String, String?) -> Void)?

    enum Modo { case menu, entrar, crear, nueva }
    @State private var modo = Modo.menu
    @State private var aviso: String?
    @State private var cargando = false
    @State private var entrando = false
    @State private var clave = ""
    @State private var repetida = ""
    @State private var problema: Clave.Problema?
    @FocusState private var enfoque: Int?

    var body: some View {
        VStack(spacing: 14) {
            switch modo {
            case .menu: menu.transition(.desenfoque)
            case .entrar: entrar.transition(.desenfoque)
            case .crear, .nueva: crear.transition(.desenfoque)
            }
        }
        .frame(maxWidth: 320)
        .padding(.horizontal, Lujo.margen)
        .padding(.bottom, 24)
        .animation(Lujo.curva(), value: modo)
        .onAppear { if vuelve && Clave.existe { modo = .entrar } }
        .sensoryFeedback(.error, trigger: problema) { _, nuevo in nuevo != nil }
    }

    // MARK: Menú (Apple, invitado, crear clave)

    private var menu: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton(.continue) { pedido in
                pedido.requestedScopes = [.fullName]
                withAnimation(Lujo.curva()) { cargando = true; aviso = nil }
            } onCompletion: { resultado in
                withAnimation(Lujo.curva()) { cargando = false }
                switch resultado {
                case .success(let autorizacion):
                    guard let credencial = autorizacion.credential as? ASAuthorizationAppleIDCredential else {
                        aviso = Idioma.texto("Apple no envió tus datos. Inténtalo otra vez o entra como invitado.")
                        return
                    }
                    entrando = true
                    alApple?(credencial.user, credencial.fullName?.givenName)
                case .failure(let error):
                    withAnimation(Lujo.curva()) { aviso = Self.mensaje(para: error) }
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: Lujo.altoBoton)
            .clipShape(RoundedRectangle(cornerRadius: Lujo.radioBoton, style: .continuous))
            .opacity(cargando ? 0.55 : 1)
            .allowsHitTesting(!cargando && !entrando)

            BotonSecundarioLujo("Entrar como invitado") {
                guard !entrando else { return }
                entrando = true
                alEntrar()
            }
            .disabled(cargando)

            if !vuelve {
                BotonTerciarioLujo(titulo: "Crear una clave", icono: .llave) {
                    limpiar()
                    withAnimation(Lujo.curva()) { modo = .crear }
                }
            }

            Group {
                if cargando {
                    HStack(spacing: 10) {
                        PuntoQueRespira()
                        Text("Conectando con Apple…")
                    }
                } else if let aviso {
                    Text(verbatim: aviso)
                } else {
                    Text("Sin correo: todo se queda en tu teléfono.")
                }
            }
            .font(.zenoTexto(.caption))
            .foregroundStyle(Lujo.marfilSecundario)
            .multilineTextAlignment(.center)
            .frame(minHeight: 30)
        }
    }

    // MARK: Entrar con la clave

    private var entrar: some View {
        VStack(alignment: .leading, spacing: 14) {
            EtiquetaLujo("Tu clave")
            CampoDeClave(texto: $clave, sugerencia: "Escribe tu clave", error: problema != nil,
                         enfocado: $enfoque, indice: 0) { comprobar() }
            mensajeDeProblema
            BotonPrimarioLujo(cargando ? "Entrando…" : "Entrar", accion: comprobar)
                .disabled(cargando)
            HStack {
                if Clave.puedeUsarFaceID {
                    BotonTerciarioLujo(titulo: LocalizedStringKey(Idioma.texto("Usar \(Clave.nombreBiometria)")), icono: .cara) {
                        Task { await conFaceID(recuperar: false) }
                    }
                    .padding(.leading, -12)
                }
                Spacer()
                BotonTerciarioLujo(titulo: "¿Olvidaste tu clave?") {
                    Task { await conFaceID(recuperar: true) }
                }
                .padding(.trailing, -12)
            }
        }
        .onAppear { enfoque = 0 }
    }

    // MARK: Crear (o elegir una nueva tras recuperar)

    private var crear: some View {
        VStack(alignment: .leading, spacing: 14) {
            EtiquetaLujo(modo == .nueva ? "Clave nueva" : "Crea tu clave")
            CampoDeClave(texto: $clave, sugerencia: "Una clave", error: problema != nil,
                         enfocado: $enfoque, indice: 0) { enfoque = 1 }
            CampoDeClave(texto: $repetida, sugerencia: "Repítela", error: problema == .noCoinciden,
                         enfocado: $enfoque, indice: 1) { guardarNueva() }
            if let problema {
                Text(verbatim: problema.mensaje)
                    .font(.zenoTexto(.caption))
                    .foregroundStyle(Lujo.rojizo)
                    .transition(.opacity)
            } else {
                Text("Al menos \(Clave.minimo) caracteres. Solo vive en este iPhone.")
                    .font(.zenoTexto(.caption))
                    .foregroundStyle(Lujo.marfilSecundario)
            }
            BotonPrimarioLujo("Guardar clave", accion: guardarNueva)
            if modo == .crear {
                BotonTerciarioLujo(titulo: "Volver", icono: .atras) {
                    limpiar()
                    withAnimation(Lujo.curva()) { modo = .menu }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { enfoque = 0 }
    }

    @ViewBuilder
    private var mensajeDeProblema: some View {
        if let problema {
            Text(verbatim: problema.mensaje)
                .font(.zenoTexto(.caption))
                .foregroundStyle(Lujo.rojizo)
                .transition(.opacity)
        }
    }

    // MARK: Acciones

    private func limpiar() {
        clave = ""; repetida = ""; problema = nil
    }

    private func comprobar() {
        guard !cargando else { return }
        withAnimation(Lujo.curva()) { problema = nil; cargando = true }
        let texto = clave
        Task {
            // La huella se calcula fuera de la pantalla; un instante de espera se siente cuidadoso.
            async let resultado = Task.detached { Clave.comprobar(texto) }.value
            try? await Task.sleep(for: .milliseconds(450))
            let fallo = await resultado
            withAnimation(Lujo.curva()) {
                cargando = false
                problema = fallo
            }
            if fallo == nil {
                enfoque = nil
                entrando = true
                alEntrar()
            } else {
                clave = ""
            }
        }
    }

    private func guardarNueva() {
        if let fallo = Clave.validar(nueva: clave, repetida: repetida) {
            withAnimation(Lujo.curva()) { problema = fallo }
            return
        }
        Clave.guardar(clave)
        enfoque = nil
        limpiar()
        entrando = true
        alEntrar()
    }

    /// Face ID (o el código del iPhone): entra directamente, o permite elegir una clave nueva.
    private func conFaceID(recuperar: Bool) async {
        let motivo = recuperar ? Idioma.texto("Confirma que eres tú para elegir una clave nueva.")
                               : Idioma.texto("Confirma que eres tú para entrar en ZENO.")
        guard await Clave.confirmarDueno(motivo: motivo) else {
            if !Clave.puedeUsarFaceID {
                withAnimation(Lujo.curva()) {
                    aviso = Idioma.texto("Este iPhone no tiene Face ID ni código. Escribe tu clave.")
                }
            }
            return
        }
        if recuperar {
            limpiar()
            withAnimation(Lujo.curva()) { modo = .nueva }
        } else {
            entrando = true
            alEntrar()
        }
    }

    /// Un mensaje claro para cada error de Apple. Cancelar no es un error: no se dice nada.
    static func mensaje(para error: Error) -> String? {
        guard let codigo = (error as? ASAuthorizationError)?.code else {
            return Idioma.texto("No se pudo entrar con Apple. Revisa tu conexión o entra como invitado.")
        }
        switch codigo {
        case .canceled:
            return nil
        case .failed, .invalidResponse:
            return Idioma.texto("Apple no pudo confirmar tu cuenta. Inténtalo otra vez en un momento.")
        case .notHandled, .notInteractive:
            return Idioma.texto("Tu iPhone no pudo mostrar la entrada con Apple. Inténtalo otra vez.")
        default:
            // Pasa mientras la app no tenga activada la capacidad "Sign in with Apple".
            return Idioma.texto("Entrar con Apple aún no está listo en esta versión. Puedes entrar como invitado.")
        }
    }
}

/// Campo de clave: oculta por defecto, con un ojo fino para mostrarla. Línea dorada al escribir,
/// rojiza si hubo un error. Sin autocorrección ni mayúsculas automáticas.
struct CampoDeClave: View {
    @Binding var texto: String
    let sugerencia: LocalizedStringKey
    var error = false
    var enfocado: FocusState<Int?>.Binding
    let indice: Int
    var alEnviar: () -> Void = {}
    @State private var visible = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Group {
                    if visible {
                        TextField("", text: $texto, prompt: Text(sugerencia).foregroundStyle(Lujo.marfil.opacity(0.3)))
                    } else {
                        SecureField("", text: $texto, prompt: Text(sugerencia).foregroundStyle(Lujo.marfil.opacity(0.3)))
                    }
                }
                .font(.zenoTexto(.body))
                .foregroundStyle(Lujo.marfil)
                .tint(Lujo.oro)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.password)
                .submitLabel(.go)
                .focused(enfocado, equals: indice)
                .onSubmit(alEnviar)

                Button {
                    visible.toggle()
                    enfocado.wrappedValue = indice
                } label: {
                    IconoFino(icono: visible ? .ojoCerrado : .ojo, color: Lujo.marfilSecundario, tamano: 18)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(visible ? Text("Ocultar la clave") : Text("Mostrar la clave"))
            }
            .padding(.leading, 16)
            .frame(height: 52)
            ZStack(alignment: .leading) {
                Rectangle().fill(error ? Lujo.rojizo.opacity(0.7) : Lujo.marfil.opacity(0.10))
                Rectangle()
                    .fill(LinearGradient(colors: [Lujo.oro, Lujo.oro.opacity(0.15)], startPoint: .leading, endPoint: .trailing))
                    .scaleEffect(x: enfocado.wrappedValue == indice && !error ? 1 : 0.0001, anchor: .leading)
            }
            .frame(height: 0.75)
            .animation(Lujo.curva(), value: enfocado.wrappedValue)
            .animation(Lujo.curva(), value: error)
        }
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Lujo.marfil.opacity(0.035)))
        .contentShape(Rectangle())
        .onTapGesture { enfocado.wrappedValue = indice }
    }
}
