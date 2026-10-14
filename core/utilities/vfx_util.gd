## © [2026] A7 Studio. All rights reserved. Trademark.
##
## Helpers for short-lived visual effects that free themselves.
class_name VfxUtil
extends RefCounted

## Extra seconds a burst waits after its lifetime before the safety timer frees it, in case [signal GPUParticles2D.finished] never fires.
const BURST_SAFETY_MARGIN: float = 0.5


## Plays a one-shot particle burst at [param at] (global) under [param parent] and frees it once it is over.
## [br]The [param material] and [param texture] are shared, build them once and reuse them for every burst.
static func burst(
	parent: Node,
	at: Vector2,
	material: ParticleProcessMaterial,
	texture: Texture2D,
	amount: int,
	lifetime: float,
	explosiveness: float = 1.0,
	randomness: float = 0.0,
	z: int = 0
) -> GPUParticles2D:
	var particles: GPUParticles2D = GPUParticles2D.new()
	particles.process_material = material
	particles.texture = texture
	particles.amount = amount
	particles.lifetime = lifetime
	particles.explosiveness = explosiveness
	particles.randomness = randomness
	particles.z_index = z
	particles.one_shot = true
	parent.add_child(particles)
	particles.global_position = at
	particles.emitting = true

	SignalUtil.connects([{SignalUtil.WHO: particles, SignalUtil.WHAT: "finished", SignalUtil.TO: particles.queue_free}])
	free_after(particles, lifetime + BURST_SAFETY_MARGIN)
	return particles


## Frees [param node] after [param seconds]. Nothing happens if the node is already gone, [param node] must be in the tree.
static func free_after(node: Node, seconds: float) -> void:
	SignalUtil.connects([
		{SignalUtil.WHO: node.get_tree().create_timer(seconds), SignalUtil.WHAT: "timeout", SignalUtil.TO: node.queue_free},
	])


## Builds a color ramp from [param stops] ([code]offset -> color[/code], applied in insertion order).
## [codeblock]
## var ramp: GradientTexture1D = VfxUtil.make_ramp({0.0: Color.YELLOW, 1.0: Color(Color.YELLOW, 0.0)})
## [/codeblock]
static func make_ramp(stops: Dictionary[float, Color]) -> GradientTexture1D:
	var gradient: Gradient = Gradient.new()
	for offset: float in stops:
		gradient.add_point(offset, stops[offset])

	var ramp: GradientTexture1D = GradientTexture1D.new()
	ramp.gradient = gradient
	return ramp
