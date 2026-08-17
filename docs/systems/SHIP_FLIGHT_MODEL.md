# Ship Flight Model

`ShipFlightModel.gd` — pure helpers used by `ShipController`.

| Regime | Behavior |
|--------|----------|
| Vacuum | low damp, full top speed, weak gravity |
| Atmosphere | envelope `t²` density (OS-B); quadratic drag; climb ceiling; lower top speed |
| SCM | balanced; partial gravity in atmo |
| NAV | high thrust mult, low damp, reduced mouse sens |
| HOVER | cancel g + radial damp; pad approach assist |
| Land | rejected if spd>22 or sink>14 |

Updated: 2026-08-07T23:18:08.396968+00:00
