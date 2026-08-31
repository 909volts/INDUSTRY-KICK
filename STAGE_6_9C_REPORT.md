# Stage 6.9C — Force DspSmoke Rebuild

## Evidence
The supposed Stage 6.9B run still printed `Stage69TestRenders` and did not print
`numericalSilence=`.

The actual Stage 6.9B source contains both `Stage69BTestRenders` and the
`numericalSilence=` diagnostic.

Therefore the runtime executable was stale.

## Change
No DSP change.
No validator logic change.
No threshold change.

The runner now:
1. copies the exact same Stage 6.9B DspSmoke.cpp;
2. verifies source identity;
3. forces its timestamp to now;
4. deletes only DspSmoke.obj / DspSmoke executable / PDB artifacts;
5. rebuilds DspSmoke;
6. captures runtime output;
7. refuses to continue unless runtime output proves the Stage 6.9B binary is running;
8. builds VST3 only if that verified DspSmoke passes.
