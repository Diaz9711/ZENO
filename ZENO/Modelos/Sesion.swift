import Foundation
import AuthenticationServices

/// La sesión de ZENO. No hay servidor ni contraseña: "tener la sesión abierta" significa
/// que la persona entró (con Apple o como invitada) y no la ha cerrado. Se guarda en el teléfono,
/// así que se mantiene al cerrar y abrir la app.
/// Cerrar sesión no borra nada: la estrella, las tareas y el historial esperan a que vuelva.
/// (Para borrar todo está "Borrar mis datos".)
enum Sesion {
    /// Clave de `@AppStorage`. Por defecto abierta, para quien ya usaba ZENO antes de existir esto.
    static let clave = "sesionAbierta"

    /// Si entró con Apple y luego quitó el permiso (Ajustes del iPhone → Apple ID), la sesión se cierra.
    static func sigueValida(cuentaApple: String?) async -> Bool {
        guard let cuentaApple else { return true }          // invitado: siempre válida
        return await withCheckedContinuation { seguir in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: cuentaApple) { estado, _ in
                // "No encontrado" también pasa sin la capacidad activada: no se echa a nadie por eso.
                seguir.resume(returning: estado != .revoked)
            }
        }
    }
}
