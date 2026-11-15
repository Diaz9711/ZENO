import SwiftUI

/// "Cómo funciona ZENO": el porqué de cada idea, en lenguaje sencillo y con estudios reales.
/// Es una página dentro de Ajustes (nunca una hoja de sistema). Cada fuente se comprobó en
/// PubMed o en la revista el 14 nov 2026; no añadir citas sin verificarlas.
struct ComoFuncionaView: View {
    var alCerrar: () -> Void

    private struct Idea: Identifiable {
        let id: Int
        let etiqueta: LocalizedStringKey
        let titulo: LocalizedStringKey
        let texto: LocalizedStringKey
        let enZeno: LocalizedStringKey
        let fuentes: [Fuente]
    }

    struct Fuente: Hashable {
        /// La cita tal cual (autores, año, revista): no se traduce.
        let cita: String
        let enlace: URL
    }

    private let ideas: [Idea] = [
        Idea(id: 0,
             etiqueta: "Tareas pequeñas",
             titulo: "Empezar es lo más difícil",
             texto: "En un estudio con 360 niños y jóvenes con TDAH, elegían más que otros una recompensa pequeña y rápida en vez de una mayor que tardaba, sobre todo cuando así esperaban menos. Una tarea grande es una recompensa lejana. Y en un ensayo con adultos con TDAH que ya tomaban medicación, un programa con un terapeuta, que enseñaba entre otras cosas a partir las tareas abrumadoras en pasos, dio mejores resultados que unas sesiones de relajación con información, y la mejora se mantenía a los 12 meses. ZENO no es esa terapia ni la sustituye: solo toma la idea de los pasos pequeños.",
             enZeno: "Por eso ZENO te pregunta el primer paso de dos minutos y te propone una sola cosa a la vez.",
             fuentes: [
                Fuente(cita: "Marco R et al. (2009). Delay and reward choice in ADHD: an experimental test of the role of delay aversion. Neuropsychology 23(3):367–380.",
                       enlace: URL(string: "https://doi.org/10.1037/a0014914")!),
                Fuente(cita: "Safren SA et al. (2010). Cognitive behavioral therapy vs relaxation with educational support for medication-treated adults with ADHD. JAMA 304(8):875–880.",
                       enlace: URL(string: "https://doi.org/10.1001/jama.2010.1192")!)
             ]),
        Idea(id: 1,
             etiqueta: "Energía",
             titulo: "Tu reloj es tuyo",
             texto: "Una revisión de 62 estudios encontró, de forma consistente, que el TDAH se asocia a un cronotipo más tardío (más \"de noche\"): el reloj interno y el sueño llegan más tarde. No todas las horas son iguales para todos.",
             enZeno: "Por eso ZENO parte de tus horas, aprende cuándo rindes y propone lo difícil cuando tienes más energía. Con poca, te deja descansar.",
             fuentes: [
                Fuente(cita: "Coogan AN, McGowan NM (2017). A systematic review of circadian function, chronotype and chronotherapy in ADHD. Atten Defic Hyperact Disord 9(3):129–147.",
                       enlace: URL(string: "https://doi.org/10.1007/s12402-016-0214-5")!)
             ]),
        Idea(id: 2,
             etiqueta: "Ceguera del tiempo",
             titulo: "Que el tiempo se vea",
             texto: "Una revisión de estudios neurocognitivos y de imagen cerebral muestra que en el TDAH hay dificultades consistentes para percibir, estimar y anticipar el tiempo, en intervalos de segundos, minutos y más largos.",
             enZeno: "Por eso, al empezar, un anillo de luz se va consumiendo alrededor de Lumi, y ZENO aprende cuánto te toman las cosas de verdad.",
             fuentes: [
                Fuente(cita: "Noreika V, Falter CM, Rubia K (2013). Timing deficits in ADHD: evidence from neurocognitive and neuroimaging studies. Neuropsychologia 51(2):235–266.",
                       enlace: URL(string: "https://doi.org/10.1016/j.neuropsychologia.2012.09.036")!)
             ]),
        Idea(id: 3,
             etiqueta: "Sin culpa",
             titulo: "Nada de regaños",
             texto: "En un estudio con 1203 adultos, quienes decían tener un diagnóstico de TDAH contaban recibir más críticas de los demás y tenían menos autocompasión, es decir, menos amabilidad consigo mismos en los momentos difíciles.",
             enZeno: "Por eso ZENO nunca regaña: no hay rachas rotas, ni números en rojo, ni tareas vencidas. \"Ahora no\" también es una respuesta válida.",
             fuentes: [
                Fuente(cita: "Beaton DM, Sirois F, Milne E (2020). Self-compassion and perceived criticism in adults with ADHD. Mindfulness 11:2506–2518.",
                       enlace: URL(string: "https://doi.org/10.1007/s12671-020-01464-w")!)
             ])
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            BotonTerciarioLujo(titulo: "Ajustes", icono: .atras) { alCerrar() }
                .padding(.leading, -12)
                .aparece(0)

            VStack(alignment: .leading, spacing: 10) {
                EtiquetaLujo("ZENO")
                Text("Cómo funciona ZENO")
                    .font(.zenoTitulo(.largeTitle))
                    .foregroundStyle(Lujo.marfil)
                    .shadow(color: .black.opacity(0.45), radius: 12, y: 2)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Cada idea de ZENO sale de lo que se sabe del TDAH. Aquí está el porqué, con sus estudios.")
                    .font(.zenoTexto(.subheadline))
                    .foregroundStyle(Lujo.marfilSecundario)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .aparece(0)

            ForEach(ideas) { idea in
                tarjeta(idea)
                    .aparece(idea.id + 1)
            }

            Text("ZENO acompaña tu día. No diagnostica ni reemplaza un tratamiento. Si algo te preocupa, habla con un profesional de salud.")
                .font(.zenoTitulo(.footnote, .regular, cursiva: true))
                .foregroundStyle(Lujo.marfil.opacity(0.55))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)
                .aparece(5)
        }
    }

    private func tarjeta(_ idea: Idea) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            EtiquetaLujo(idea.etiqueta)
            Text(idea.titulo)
                .font(.zenoTitulo(.title2, .regular))
                .foregroundStyle(Lujo.marfil)
            Text(idea.texto)
                .font(.zenoTexto(.subheadline))
                .foregroundStyle(Lujo.marfil.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Circle().fill(Lujo.oro).frame(width: 4, height: 4)
                Text(idea.enZeno)
                    .font(.zenoTexto(.subheadline, .medium))
                    .foregroundStyle(Lujo.oro)
                    .fixedSize(horizontal: false, vertical: true)
            }
            SeparadorLujo()
            VStack(alignment: .leading, spacing: 8) {
                ForEach(idea.fuentes, id: \.self) { fuente in
                    Link(destination: fuente.enlace) {
                        Text(verbatim: fuente.cita)
                            .font(.zenoTexto(.caption2))
                            .foregroundStyle(Lujo.marfilSecundario)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityHint(Text("Abre el estudio"))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tarjetaLujo()
    }
}
