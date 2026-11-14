import Foundation

/// Atajos para comparar imágenes en el simulador. En la app publicada no hacen nada.
/// `-lumiQuieta YES` congela el tiempo de Lumi y del cielo; `-energiaFija 70` fija la energía.
enum Pruebas {
    static var quieto: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "lumiQuieta")
        #else
        false
        #endif
    }

    static var energia: Double? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "energiaFija").flatMap(Double.init)
        #else
        nil
        #endif
    }
}
