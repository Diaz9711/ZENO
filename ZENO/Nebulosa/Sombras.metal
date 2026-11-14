#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Los dos dibujos vivos de ZENO: la nebulosa (fondo) y Lumi (la estrella).
// Se calculan pixel por pixel en la tarjeta gráfica; no hay imágenes.

// ───────── Ruido suave ─────────

static float azar(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float ruido(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    float a = azar(i);
    float b = azar(i + float2(1.0, 0.0));
    float c = azar(i + float2(0.0, 1.0));
    float d = azar(i + float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Varias capas de ruido: da el aspecto de nube.
static float nube(float2 p) {
    float v = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; i++) {
        v += amp * ruido(p);
        p = float2(p.x * 1.6 - p.y * 1.2, p.x * 1.2 + p.y * 1.6) + 7.3;
        amp *= 0.5;
    }
    return v / 0.9375;
}

// ───────── Nebulosa ─────────
// Ruido de mejor calidad (gradiente), para nubes sin cuadrícula ni manchas.

static float2 gradiente(float2 p) {
    float h = azar(p) * 6.2831853;
    return float2(cos(h), sin(h));
}

static float perlin(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    float a = dot(gradiente(i), f);
    float b = dot(gradiente(i + float2(1.0, 0.0)), f - float2(1.0, 0.0));
    float c = dot(gradiente(i + float2(0.0, 1.0)), f - float2(0.0, 1.0));
    float d = dot(gradiente(i + float2(1.0, 1.0)), f - float2(1.0, 1.0));
    return clamp(0.5 + 0.72 * mix(mix(a, b, u.x), mix(c, d, u.x), u.y), 0.0, 1.0);
}

static float gasN(float2 p, int capas) {
    float v = 0.0, amp = 0.5, total = 0.0;
    for (int i = 0; i < capas; i++) {
        v += amp * perlin(p);
        total += amp;
        p = float2(p.x * 1.62 - p.y * 1.18, p.x * 1.18 + p.y * 1.62) + 11.7;
        amp *= 0.52;
    }
    return v / total;
}

// Filamentos: crestas finas y luminosas.
static float crestas(float2 p) {
    float v = 0.0, amp = 0.5, total = 0.0;
    for (int i = 0; i < 4; i++) {
        float c = 1.0 - abs(2.0 * perlin(p) - 1.0);
        v += amp * c * c;
        total += amp;
        p = float2(p.x * 1.7 - p.y * 1.1, p.x * 1.1 + p.y * 1.7) + 5.3;
        amp *= 0.5;
    }
    return v / total;
}

// Una capa de estrellas: `celda` es el tamaño de la rejilla en puntos.
static float estrellas(float2 pos, float celda, float densidad, float radio, float t, float2 semilla) {
    float2 g = pos / celda;
    float2 id = floor(g);
    float h = azar(id + semilla);
    float2 centro = 0.5 + 0.34 * (float2(azar(id + semilla + 3.1), azar(id + semilla + 7.9)) - 0.5);
    float dist = length(fract(g) - centro) * celda;
    float brilla = step(1.0 - densidad, h);
    float titila = 0.65 + 0.35 * sin(t * (0.5 + 2.2 * fract(h * 57.0)) + h * 90.0);
    float nucleo = exp(-dist * dist / (radio * radio));
    float aura = 0.22 * exp(-dist * dist / (radio * radio * 9.0));
    return (nucleo + aura) * brilla * titila * (0.45 + 0.55 * fract(h * 131.0));
}

// Lucecitas que flotan despacio, como luciérnagas: cada una vive en su celda,
// se pasea en ella y se enciende y se apaga con calma.
static float lucecitas(float2 pos, float celda, float radio, float t, float2 semilla) {
    float2 g = pos / celda;
    float2 id = floor(g);
    float h = azar(id + semilla);
    float h2 = fract(h * 113.0);
    float2 paseo = float2(sin(t * (0.10 + 0.14 * h2) + h * 40.0),
                          cos(t * (0.08 + 0.12 * h) + h2 * 70.0));
    float dist = length(fract(g) - (0.5 + 0.27 * paseo)) * celda;
    float presente = step(0.62, h);
    float pulso = smoothstep(0.15, 0.85, 0.5 + 0.5 * sin(t * (0.22 + 0.35 * h2) + h * 30.0));
    float nucleo = exp(-dist * dist / (radio * radio));
    float aura = 0.30 * exp(-dist * dist / (radio * radio * 10.0));
    return (nucleo + aura) * presente * pulso;
}

[[ stitchable ]] half4 nebulosa(float2 pos, half4 color,
                                float2 tam, float2 centro, float t, float2 inclina,
                                float2 desplazamiento, float energia, float calidez,
                                float3 cFondo, float3 cNube, float3 cBrasa, float3 cOro)
{
    float escala = min(tam.x, tam.y);
    float2 uv = (pos - centro) / escala;
    float d = length(uv);

    // El gas se arremolina muy levemente alrededor de la estrella.
    float giro = 0.50 * exp(-d * 1.5) + t * 0.0035;
    float cg = cos(giro), sg = sin(giro);
    float2 ru = float2(uv.x * cg - uv.y * sg, uv.x * sg + uv.y * cg);

    // Gas que se pliega sobre sí mismo, muy despacio.
    // Al inclinar el teléfono, el gas se corre un poco: lo lejano se mueve menos que lo cercano.
    float2 p = ru * 1.30 + desplazamiento + inclina * 0.035;
    float2 q = float2(gasN(p + float2(0.0, t * 0.020), 3),
                      gasN(p + float2(5.2, 1.3) - float2(t * 0.016, 0.0), 3));
    float2 r = float2(gasN(p + 1.9 * q + float2(1.7, 9.2) + t * 0.011, 3),
                      gasN(p + 1.9 * q + float2(8.3, 2.8) - t * 0.009, 3));
    float n = gasN(p + 1.8 * r, 5);                          // densidad principal
    float fila = crestas(p * 1.55 + 1.3 * r + 4.0);          // filamentos
    float polvo = gasN(p * 2.2 - 1.5 * q + 11.0, 4);         // vetas oscuras

    // La energía cambia la luz, no el detalle: la calidad es la misma en todo el recorrido.
    float luzE = mix(0.84, 1.0, energia);
    // Detalle fino: deshilacha los bordes de las nubes para que no parezcan manchas lisas.
    float fino = gasN(p * 3.6 + 2.4 * r + 23.0, 2);
    float dens = smoothstep(0.30, 0.74, n + (fino - 0.5) * 0.18);
    float pliegue = smoothstep(0.58, 0.92, length(r) * 1.15);

    // Profundidad: cielo hondo, nube, y un color de acento en los pliegues.
    float3 cAcento = mix(cNube, cBrasa, 0.55);
    float3 col = cFondo * mix(0.80, 1.06, calidez);
    col = mix(col, cNube, dens * 0.74);
    col = mix(col, cAcento, pliegue * dens * 0.38);
    // Zonas un poco más frías y otras más cálidas: el cielo deja de ser de un solo tono.
    col *= mix(float3(1.0), float3(0.82, 0.96, 1.12), 0.45 * smoothstep(0.42, 0.72, q.x));
    col *= mix(float3(1.0), float3(1.10, 0.94, 1.04), 0.40 * smoothstep(0.45, 0.75, q.y));
    // Los bordes de las nubes atrapan luz, más del lado de la estrella.
    float borde = dens * (1.0 - dens) * 4.0;
    col += mix(cNube, cBrasa, 0.30) * borde * fino * (0.10 + 0.22 * exp(-d * 1.6)) * luzE;

    // Filamentos luminosos, más visibles donde hay gas.
    float hilo = pow(fila, 3.0);
    col += mix(cBrasa, cNube, 0.35) * hilo * (0.10 + 0.34 * dens) * luzE;

    // El centro se enciende: el resplandor de una estrella naciendo.
    float apertura = 3.4 - 0.8 * energia - 1.0 * calidez;
    float calor = exp(-d * d * apertura);
    float velo = 0.74 + 0.44 * n + 0.30 * hilo;
    col = mix(col, cBrasa, clamp(calor * velo * mix(0.30, 0.58, calidez) * luzE, 0.0, 1.0));
    col += cOro * pow(calor, 2.4) * velo * mix(0.10, 0.24, energia) * mix(0.70, 1.0, calidez);
    col += cBrasa * 0.05 * calidez * dens;

    // Vetas de polvo oscuro: dan contraste y sensación de volumen.
    float veta = smoothstep(0.52, 0.78, polvo);
    col *= 1.0 - 0.34 * veta * (1.0 - 0.8 * calor);

    // Estrellas en tres profundidades; el gas denso las tapa un poco.
    float tapa = 1.0 - 0.60 * dens;
    float3 cEstrella = float3(1.0, 0.95, 0.88);
    float2 posCerca = pos + inclina * 14.0;
    float lejos = estrellas(pos + inclina * 3.0, 7.0, 0.050, 0.55, t, desplazamiento);
    float medias = estrellas(pos + inclina * 7.0, 19.0, 0.060, 0.85, t, desplazamiento + 17.0);
    float cerca = estrellas(posCerca, 53.0, 0.090, 1.35, t, desplazamiento + 41.0);
    float3 tinte = mix(float3(0.78, 0.86, 1.0), float3(1.0, 0.88, 0.72), azar(floor(posCerca / 53.0) + 2.0));
    col += cEstrella * (lejos * 0.42 + medias * 0.70) * tapa * (1.0 - calor);
    col += tinte * cerca * 0.95 * tapa * (1.0 - calor);

    // Viñeta suave; el piso nunca baja del color del cielo.
    col *= 1.0 - 0.24 * smoothstep(0.45, 1.25, d);
    col *= luzE;
    col = max(col, cFondo * 0.74);

    // Lucecitas doradas en dos distancias, delante del gas. Son lo más cercano:
    // al inclinar el teléfono se mueven más que todo lo demás.
    float2 sube = float2(0.0, -t * 2.2);
    float luzLejos = lucecitas(pos + inclina * 22.0 + sube, 104.0, 1.5, t, desplazamiento + 5.0);
    float luzCerca = lucecitas(pos + inclina * 38.0 + sube * 1.7, 171.0, 2.5, t * 0.8, desplazamiento + 29.0);
    col += mix(cOro, float3(1.0, 0.93, 0.80), 0.35) * (luzLejos * 0.55 + luzCerca * 0.42) * (1.0 - 0.7 * calor);

    // Grano finísimo contra el bandeado.
    col += (azar(pos + fract(t)) - 0.5) / 160.0;

    return half4(half3(clamp(col, 0.0, 1.0)), 1.0);
}

// ───────── Lumi ─────────
// Dos formas, que nunca se mezclan (juntas se veían raras):
//   forma 0 · ESTRELLA: un corazón de luz sin borde, con rayos finos y largos
//   forma 1 · ESFERA:   una bola dorada de luz líquida que gira, con volumen
// Las dos comparten resplandor, halo del color de la persona y motas en órbita.

[[ stitchable ]] half4 lumi(float2 pos, half4 color,
                            float2 tam, float t, float2 desplazamiento,
                            float energia, float respiro, float giro,
                            float lobulos, float profundidad, float destello,
                            float fase, float ola, float2 orbita, float forma_,
                            float3 cNucleo, float3 cCorona, float3 cHalo)
{
    float2 uv = (pos - tam * 0.5) / (min(tam.x, tam.y) * 0.5);
    float d = length(uv);
    float a = atan2(uv.y, uv.x);
    float2 dir = uv / max(d, 0.0001);
    bool esEsfera = forma_ > 0.5;

    float brillo = mix(0.70, 1.0, energia) + 0.12 * destello;

    // ── Halo (común) ──
    float ondaH = 0.62 * sin(a * lobulos + giro)
                + 0.38 * sin(a * (lobulos - 1.0) - giro * 0.6 + desplazamiento.x);
    float gas = ruido(dir * 1.7 + desplazamiento + float2(t * 0.05, -t * 0.04)) - 0.5;
    float forma = 1.0 + profundidad * ondaH * (0.6 + 0.4 * energia) + 0.20 * gas;
    float rHalo = mix(0.50, 0.80, energia) * (1.0 + mix(0.04, 0.10, energia) * respiro) * forma;
    float halo = exp(-pow(d / rHalo, 1.45) * 2.0);

    // ── Motas en órbita ladeada (común) ──
    float co = cos(orbita.y), so = sin(orbita.y);
    float motas = 0.0;
    for (int i = 0; i < 9; i++) {
        float fi = float(i);
        float h1 = azar(float2(fi * 1.31, 7.7) + desplazamiento);
        float h2 = azar(float2(fi * 2.17, 3.1) + desplazamiento);
        float vel = 0.07 + 0.09 * h1;
        float ang = h2 * 6.2832 + giro * 0.4 + t * vel;
        float rad = mix(0.40, 0.72, h1) * mix(0.80, 1.0, energia) + 0.02 * sin(t * (0.3 + h2) + fi);
        float2 po = rad * float2(cos(ang), sin(ang) * orbita.x);
        float2 pm = float2(po.x * co - po.y * so, po.x * so + po.y * co);
        float dm = length(uv - pm);
        float pulso = 0.55 + 0.45 * sin(t * (0.7 + 1.3 * h1) + fi * 2.4);
        float cerca = 0.75 + 0.25 * sin(ang);       // las de adelante brillan más
        motas += (0.8 * exp(-dm * dm / 0.00014) + 0.22 * exp(-dm * dm / 0.0020)) * pulso * cerca;
    }

    float3 col = cHalo * halo * mix(0.40, 0.60, energia);
    float disco = 0.0;
    float3 esfera = float3(0.0);

    if (!esEsfera) {
        // ═════ ESTRELLA ═════
        float3 cClaro = mix(cNucleo, float3(1.0, 0.97, 0.90), 0.45);
        float rN = mix(0.078, 0.108, energia) * (1.0 + 0.055 * respiro);
        float x = d / rN;
        float corazon = exp(-x * x * 0.85);
        float vivo = nube(uv / rN * 0.8 + desplazamiento + float2(t * 0.04, -t * 0.03));
        float pegado = 1.0 / (1.0 + pow(x / 1.45, 2.0));
        float fil = nube(dir * 1.25 + desplazamiento + (x * 0.12 - t * 0.035));
        float medio = 1.0 / (1.0 + pow(x / mix(2.9, 3.9, energia), 2.0));
        medio *= 0.74 + 0.52 * fil;
        float velo = exp(-pow((d - rHalo * 0.84) / 0.075, 2.0)) * (0.4 + 0.6 * fil);

        // Rayos: líneas finas que se afilan hacia la punta. Cada persona tiene
        // su número (4 a 8) y su danza (laten juntos, o una ola los recorre).
        float nR = lobulos + 1.0;
        float largo = mix(0.46, 0.80, energia) * (1.0 + 0.09 * respiro);
        float rayos = 0.0;
        float rayosCortos = 0.0;
        for (int i = 0; i < 8; i++) {
            float fi = float(i);
            float activo = step(fi + 0.5, nR);
            float ang = giro * 0.35 + desplazamiento.y + 6.2831853 * fi / nR;
            float danza = sin(t * 0.75 - fi * ola * 6.2831853 / nR);

            float2 e = float2(cos(ang), sin(ang));
            float al = dot(uv, e);
            float pe = abs(uv.x * e.y - uv.y * e.x);
            float L = largo * (0.82 + 0.18 * danza);
            float w = 0.0040 + 0.0105 * clamp(1.0 - al / L, 0.0, 1.0);
            float linea = exp(-pe * pe / (w * w)) + 0.22 * exp(-pe * pe / (w * w * 20.0));
            rayos += activo * smoothstep(-0.01, 0.03, al) * linea * exp(-al / L * 2.5);

            float ang2 = ang + 3.14159265 / nR;
            float2 e2 = float2(cos(ang2), sin(ang2));
            float al2 = dot(uv, e2);
            float pe2 = abs(uv.x * e2.y - uv.y * e2.x);
            float L2 = L * 0.46;
            float w2 = 0.0032 + 0.0075 * clamp(1.0 - al2 / L2, 0.0, 1.0);
            float linea2 = exp(-pe2 * pe2 / (w2 * w2)) + 0.20 * exp(-pe2 * pe2 / (w2 * w2 * 20.0));
            rayosCortos += activo * smoothstep(-0.01, 0.03, al2) * linea2 * exp(-al2 / L2 * 2.5);
        }
        // Rayitos muy finos pegados al corazón.
        float brasa = pow(nube(dir * 5.5 + desplazamiento + float2(t * 0.05, giro)), 3.0) * exp(-x * 0.55) * 2.2;

        col += mix(cHalo, cCorona, 0.35) * velo * mix(0.02, 0.10, energia);
        col += cCorona * medio * 1.05 * brillo;
        col += mix(cNucleo, cCorona, 0.40) * pegado * 0.95 * brillo;
        col += cCorona * brasa * 0.20 * brillo;
        col += mix(mix(cClaro, cCorona, 0.30), cHalo, 0.15) * rayos * 0.95 * brillo;
        col += mix(mix(cClaro, cCorona, 0.40), cHalo, 0.20) * rayosCortos * 0.60 * brillo;
        col += cClaro * corazon * (1.9 + 0.5 * (vivo - 0.5)) * brillo;
    } else {
        // ═════ ESFERA ═════
        float rN = mix(0.200, 0.262, energia) * (1.0 + 0.040 * respiro);
        float x = d / rN;
        float2 sp = uv / rN;
        float z = sqrt(max(1.0 - x * x, 0.0));
        float3 n = float3(sp.x, sp.y, z);

        // La bola gira sobre su eje: la textura se envuelve en ella.
        float rot = giro * 1.6 + desplazamiento.x;
        float cr = cos(rot), sr = sin(rot);
        float3 q3 = float3(n.x * cr + n.z * sr, n.y, -n.x * sr + n.z * cr);
        float2 q = float2(q3.x, q3.y) * 1.25 + float2(q3.z * 0.9, q3.z * 0.55) + desplazamiento;

        float w1 = nube(q + float2(t * 0.020, -t * 0.015));
        float w2 = nube(q * 1.35 + 1.9 * w1 + float2(-t * 0.018, t * 0.024));
        float flujo = smoothstep(0.22, 0.80, w2);
        float vetas = pow(smoothstep(0.45, 0.95, nube(q * 2.1 + 2.4 * w2 + 3.7)), 2.0);
        float granos = ruido(q * 6.5 + 3.0 * w1 + float2(t * 0.05, t * 0.04));

        float luz = clamp(dot(n, normalize(float3(-0.22, -0.34, 0.92))), 0.0, 1.0);
        float3 cHondo = cCorona * float3(0.92, 0.80, 0.74);
        float3 cMedio = mix(cCorona, cNucleo, 0.55);
        float3 cClaro = mix(cNucleo, float3(1.0, 0.97, 0.90), 0.55);

        esfera = mix(cHondo, cMedio, smoothstep(0.05, 0.75, luz));
        esfera = mix(esfera, cClaro, pow(luz, 3.2) * 0.80);
        esfera *= 0.88 + 0.20 * flujo + 0.07 * (granos - 0.5);
        esfera += cClaro * vetas * 0.16 * mix(0.75, 1.0, energia);
        esfera += cClaro * pow(z, 5.0) * (0.08 + 0.06 * respiro);   // el corazón late
        float borde = pow(1.0 - z, 2.6);
        esfera += mix(cCorona, cHalo, 0.40) * borde * 0.42;
        esfera *= 0.78 + 0.26 * brillo;

        disco = smoothstep(1.015, 1.0 - mix(0.085, 0.045, energia), x);

        float fuera = max(x - 1.0, 0.0);
        float fil = nube(dir * 1.25 + desplazamiento + (x * 0.30 - t * 0.035));
        float pegado = 1.0 / (1.0 + pow(fuera * 4.2, 2.0));
        float medio = 1.0 / (1.0 + pow(fuera * mix(2.1, 1.15, energia), 2.0));
        medio *= 0.72 + 0.56 * fil;
        float velo = exp(-pow((d - rHalo * 0.84) / 0.075, 2.0)) * (0.4 + 0.6 * fil);

        col += mix(cHalo, cCorona, 0.35) * velo * mix(0.02, 0.10, energia);
        col += cCorona * medio * 0.95 * brillo;
        col += mix(cNucleo, cCorona, 0.35) * pegado * 0.95 * brillo;
    }

    col = 1.0 - exp(-col * 1.20);                   // curva suave: no se quema
    col = mix(col, clamp(esfera, 0.0, 1.0), disco);
    col += mix(cNucleo, cHalo, 0.35) * motas * mix(0.10, 0.50, energia);

    // Se desvanece antes de tocar el borde del lienzo.
    float margen = smoothstep(1.0, 0.74, d);
    col *= margen;
    // Grano finísimo contra el bandeado.
    col += (azar(pos + fract(t) * 13.0) - 0.5) / 150.0;

    col = clamp(col, 0.0, 1.0);
    float alfa = max(disco * margen, max(col.r, max(col.g, col.b)));
    return half4(half3(col), half(alfa));
}
