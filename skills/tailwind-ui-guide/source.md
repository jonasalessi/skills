# Tailwind CSS guide

## Dark Mode: Respeite Seu Usuário

Background principal? bg-white dark:bg-gray-900. Texto primário? text-gray-900 dark:text-gray-100. Texto secundário? text-gray-500 dark:text-gray-400. Bordas? border-gray-200 dark:border-gray-700. Com 4-5 pares definidos, 90% dos componentes ficam cobertos.

## Paleta de Cores: HSL e a Ciência por Trás das Escolhas
HSL resolve isso. Em vez de misturar canais de luz (Red, Green, Blue), você descreve cor em termos humanos:

Hue (matiz): a posição no círculo cromático, de 0° a 360°. Vermelho = 0°, verde = 120°, azul = 240°.
Saturation (saturação): quão “viva” é a cor. 0% = cinza, 100% = cor pura.
Lightness (luminosidade): quão clara ou escura. 0% = preto, 100% = branco.

steps:
1. Passo 1: Distribuir Matizes no Círculo Cromático
Oito matizes espaçados ao redor do círculo. Não é aleatório — é a mesma lógica de uma paleta policromática em teoria das cores. Quando os matizes são equidistantes, o olho humano percebe harmonia mesmo com cores completamente diferentes. É o mesmo princípio que artistas usam com um círculo cromático de 12 cores desde o século XVIII.


2. Passo 2: Fixar Saturação e Luminosidade por Camada
Tema claro:

Backgrounds: ~92-95% luminosidade, saturação moderada. Com luminosidade tão alta, mesmo saturações diferentes resultam em cores pastel com peso visual parecido — nenhuma seção “grita” mais que outra.
Texto: ~15-20% luminosidade. Escuro o suficiente pra garantir ratio de contraste >7:1 contra o background claro (acima do mínimo WCAG AAA de 7:1).
Bordas: ~45-55% luminosidade. O acento cromático — visível mas não dominante.
Tema escuro:

Backgrounds: ~10-12% luminosidade. Profundidade uniforme — todas as seções têm a mesma “escuridão”.
Texto: ~80-85% luminosidade. Claro o suficiente pra ratio de contraste >6:1 no fundo escuro.
Bordas: mesma faixa de luminosidade que no tema claro — funcionam como acento nos dois contextos.
Na prática, isso significa que gerar a variante dark de qualquer cor é mecânico: mantém o matiz, inverte a luminosidade. Background que era 94% vira 11%. Texto que era 18% vira 83%. Não é design — é aritmética.

3. Passo 3: Verificar Contraste (WCAG)
Cores bonitas que ninguém consegue ler não servem pra nada. O padrão WCAG (Web Content Accessibility Guidelines) define ratios mínimos:

AA: 4.5:1 pra texto normal, 3:1 pra texto grande
AAA: 7:1 pra texto normal, 4.5:1 pra texto grande
Os backgrounds claros com ~95% luminosidade contra texto com ~20% luminosidade dão ratio >7:1 — WCAG AAA. Os backgrounds escuros (~11%) contra texto claro (~82%) dão >6:1 — confortavelmente WCAG AA, próximo de AAA.