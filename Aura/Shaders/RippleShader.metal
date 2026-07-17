//
//  RippleShader.metal
//  Aura
//
//  Add this file to the main app target's Compile Sources phase.
//  The [[ stitchable ]] entry point is made available in Swift as
//  ShaderLibrary.rippleDistortion(...).
//

#include <metal_stdlib>
using namespace metal;

/// Displaces the source sample position to create a radially expanding ripple.
///
/// - Parameters:
///   - position: Current pixel position, in the view's local coordinate space.
///   - time: Seconds since the current ripple began.
///   - touchPos: Ripple origin in the same coordinate space as `position`.
///   - strength: Maximum displacement in points. A practical range is 8...24.
///   - size: View size in points; used to keep frequency consistent across devices.
[[ stitchable ]]
float2 rippleDistortion(
    float2 position,
    float time,
    float2 touchPos,
    float strength,
    float2 size
) {
    constexpr float duration = 1.35;
    constexpr float speed = 620.0;       // Points per second.
    constexpr float wavelength = 52.0;   // Distance between wave crests.

    if (time < 0.0 || time > duration || strength <= 0.0) {
        return position;
    }

    float2 delta = position - touchPos;
    float distanceFromTouch = length(delta);
    float2 direction = distanceFromTouch > 0.001
        ? delta / distanceFromTouch
        : float2(0.0);

    // The travelling wave is strongest at its moving front. The Gaussian-like
    // envelope prevents the entire image from wobbling at once.
    float waveFront = time * speed;
    float distanceToFront = distanceFromTouch - waveFront;
    float frontEnvelope = exp(-pow(distanceToFront / 115.0, 2.0));

    // Global exponential damping makes the last oscillations settle naturally.
    float damping = exp(-2.85 * time);
    float phase = (distanceToFront / wavelength) * (2.0 * M_PI_F);
    float amplitude = sin(phase) * frontEnvelope * damping * strength;

    // Limit the sampled area at the edge of unusually small views. This retains
    // a stable result while preserving the outward refraction direction.
    float edgeScale = min(size.x, size.y) > 0.0 ? 1.0 : 0.0;
    return position + direction * amplitude * edgeScale;
}
