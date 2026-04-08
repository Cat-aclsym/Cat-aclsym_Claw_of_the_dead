## © [2026] A7 Studio. All rights reserved. Trademark.

shader_type canvas_item;

uniform float health_percentage : hint_range(0.0, 1.0) = 1.0;
uniform vec4 cut_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float segment_width : hint_range(0.0, 0.1) = 0.005;
uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Appliquer le flash blanc
    tex_color.rgb = mix(tex_color.rgb, flash_color.rgb, flash_intensity);
    
    // Si l'UV.x est supérieur au pourcentage de vie, on applique l'effet de "coupe"
    if (UV.x > health_percentage) {
        // On rend la partie vide plus sombre et transparente
        tex_color.a *= 0.3;
        tex_color.rgb *= 0.2;
    }
    
    // Ajouter une ligne de séparation à la limite
    float limit_dist = abs(UV.x - health_percentage);
    if (limit_dist < segment_width && health_percentage > 0.0 && health_percentage < 1.0) {
        tex_color = mix(tex_color, cut_color, 1.0 - (limit_dist / segment_width));
    }

    COLOR = tex_color;
}
