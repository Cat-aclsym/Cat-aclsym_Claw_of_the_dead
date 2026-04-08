## © [2026] A7 Studio. All rights reserved. Trademark.

shader_type canvas_item;

uniform float health_percentage : hint_range(0.0, 1.0) = 1.0;
uniform vec4 cut_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float segment_width : hint_range(0.0, 0.1) = 0.01;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Si l'UV.x est supérieur au pourcentage de vie, on applique l'effet de "coupe"
    if (UV.x > health_percentage) {
        // On peut soit rendre transparent, soit assombrir, soit utiliser une couleur spécifique
        // Pour un effet de "coupe", on va simplement multiplier l'alpha par 0.3 pour montrer la barre vide
        tex_color.a *= 0.2;
        tex_color.rgb *= 0.5;
    }
    
    // Optionnel: Ajouter une ligne de séparation à la limite
    float limit_dist = abs(UV.x - health_percentage);
    if (limit_dist < segment_width && health_percentage > 0.0 && health_percentage < 1.0) {
        tex_color = mix(tex_color, cut_color, 1.0 - (limit_dist / segment_width));
    }

    COLOR = tex_color;
}
