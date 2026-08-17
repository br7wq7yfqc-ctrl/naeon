# Ship Flight Model

`ShipFlightModel.gd` — pure helpers used by `ShipController`.

| Regime | Behavior |
|--------|----------|
| Vacuum | low damp, full top speed, weak gravity; OS-C start 8 km AGL, hold-S still geometric inward |
| Atmosphere | envelope `t²` density (OS-B); quadratic drag; climb ceiling; OS-F lift/glide in the dense layer (`aero_lift_accel`); lower top speed |
| SCM | balanced; partial gravity in atmo; wing lift when dense |
| NAV | high thrust mult, low damp, reduced mouse sens |
| HOVER | cancel g + radial damp; pad approach assist; no aero lift (VTOL) |
| Land | rejected if spd>22 or sink>14 |
| Hold-S | geometric inward; lift skipped while S is held |

Updated: 2026-08-17
