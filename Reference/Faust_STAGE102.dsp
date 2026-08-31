
// INDUSTRY KICK V2 — Stage 7.1B compile-fixed approved family processing + common master candidate
// Status: SOURCE WRITTEN, COMPILE NOT TESTED in this environment.
// Design target:
//   coherent pitched event -> family-specific source/envelope -> family-specific nonlinear topology
//   -> controlled HF cleanup.
// Space/rumble is intentionally omitted from this core freeze and will be validated separately.
//
// Final integration requirement:
//   Use Faust ADAA nonlinearities AND validate inside JUCE oversampling (2x/4x candidate modes).
//   Do not claim aliasing PASS until compiled/rendered and measured at 44.1/48/96 kHz.

import("stdfaust.lib");

clip01(x) = min(1.0,max(0.0,x));
mix(a,b,x) = a + (b-a)*clip01(x);
db2lin(x) = pow(10.0,x/20.0);

family = int(nentry("Family[style:menu{'ROUND/DARK':0;'PUNCH/ATTACK':1;'HARD/CLIPPED':2;'INDUSTRIAL/SUSTAINED':3;'RAVE/BRIGHT':4}]",0,0,4,1));
accentBank = int(nentry("AccentBank",0,0,4,1));
gate   = button("Trigger");

tune    = hslider("Tune[unit:Hz]",52,42,70,0.01);
body    = hslider("Body",0.75,0,1,0.001);
punch   = hslider("Punch",0.75,0,1,0.001);
length  = hslider("Length[unit:ms]",320,120,600,1);
drive   = hslider("Drive",0.35,0,1,0.001);
colour  = hslider("Colour",0.35,0,1,0.001);
metal   = hslider("Metal",0.15,0,1,0.001);
sub     = hslider("Sub",0.85,0,1,0.001);
impact  = hslider("Impact",0.80,0,1,0.001);
grit    = hslider("Grit",0.25,0,1,0.001);
shape   = hslider("Shape",0.25,0,1,0.001);
evolve  = hslider("Evolve",0.20,0,1,0.001);
destroy = hslider("Destroy",0.20,0,1,0.001);
clipper = hslider("Clipper",0.25,0,1,0.001);
outGain = hslider("Output[unit:dB]",-3,-18,6,0.1) : db2lin;

reset = gate > gate';

// Stage 6.4 parity correction:
// The approved offline R4/R5 prototypes used tau as an exponential time
// constant. Faust ARE uses a ~60 dB settling-time convention, so convert
// prototype tau to ARE time with the 6.91 factor documented by Faust.
tauToAre(tau) = max(0.00001, tau * 6.91);
expTauEnv(at,tau) = en.are(at,tauToAre(tau),gate);

ampEnv(decay) = expTauEnv(0.00008,decay);
pitchFast(tau) = expTauEnv(0.00001,tau);
pitchBody(tau) = expTauEnv(0.00001,tau);
transEnv(tau) = expTauEnv(0.00001,tau);

phasor(freq) = os.hs_phasor(1.0,freq,reset);
sineFromPhase(ph,h) = sin(2.0*ma.PI*ph*h);

softNL(d,a,x) = (x + a*x*abs(x))*d : aa.tanh1;
hardNL(d,x) = x*d : aa.hardclip;

// ---------------------------------------------------------------
// ROUND / DARK
// ---------------------------------------------------------------
roundFreq =
    tune
  + mix(145,225,punch)*pitchFast(mix(0.010,0.0065,punch))
  + mix(82,125,0.55*punch+0.45*body)*pitchBody(mix(0.055,0.088,body));

roundPhase = phasor(roundFreq);
// Stage 6.7: ROUND is deliberately the long, soft family.
roundDecay = min(0.90,max(0.42,(length/1000.0)*1.95));
// Stage 6.8: reduce front-loading; keep the approved long ROUND decay.
roundAmp = ampEnv(roundDecay)
           * (1.0 + mix(0.20,0.55,punch)*transEnv(mix(0.045,0.024,punch)));

roundSource =
   (sub*sineFromPhase(roundPhase,1)
   +mix(0.08,0.20,body)*sineFromPhase(roundPhase,2)
   +mix(0.015,0.055,colour)*sineFromPhase(roundPhase,3))*roundAmp
   +mix(0.015,0.070,impact*colour)*sineFromPhase(roundPhase,4)*transEnv(mix(0.022,0.012,punch));

roundSig =
    roundSource
  : fi.peak_eq_cq(mix(1.5,5.0,body),mix(82,112,body),0.8)
  : softNL(mix(1.12,1.85,drive),mix(0.003,0.025,shape))
  : fi.lowpass(4,mix(2600,5200,colour))
  : fi.high_shelf(mix(-8,-2,colour),1800)
  : fi.highpass(2,20);

// ---------------------------------------------------------------
// PUNCH / ATTACK
// ---------------------------------------------------------------
punchFreq =
    tune
  + mix(215,335,punch)*pitchFast(mix(0.0068,0.0038,punch))
  + mix(118,188,0.72*punch+0.28*body)*pitchBody(mix(0.038,0.062,body));

punchPhase = phasor(punchFreq);
// Stage 6.7: PUNCH is the shortest body family; transient stays concentrated.
punchDecay = min(0.23,max(0.110,(length/1000.0)*0.82));
punchAmp = ampEnv(punchDecay)
           * (1.0 + mix(1.05,2.00,punch)*transEnv(mix(0.028,0.016,punch)));

punchSource =
   (sub*sineFromPhase(punchPhase,1)
   +mix(0.12,0.27,body)*sineFromPhase(punchPhase,2)
   +mix(0.03,0.11,colour)*sineFromPhase(punchPhase,3))*punchAmp
   +mix(0.07,0.24,impact)*sineFromPhase(punchPhase,4)*transEnv(mix(0.017,0.007,punch))
   +mix(0.035,0.17,metal*impact)*sineFromPhase(punchPhase,6)*transEnv(mix(0.013,0.0055,punch));

punchNoise = no.noise
           : fi.highpass(2,mix(700,1300,colour))
           : fi.lowpass(2,mix(2800,5000,colour))
           : *(mix(0.012,0.075,impact*colour)*transEnv(mix(0.0065,0.0028,punch)));

punchSig =
    (punchSource + (punchNoise : softNL(mix(1.35,2.10,drive),mix(0.002,0.014,shape))))
  : fi.peak_eq_cq(mix(2.5,7.5,impact),mix(102,138,punch),0.85)
  : softNL(mix(1.10,1.58,drive),mix(0.003,0.020,shape))
  : fi.lowpass(4,mix(5200,9000,colour))
  : fi.highpass(2,20);

// ---------------------------------------------------------------
// HARD / CLIPPED — serial nonlinear stages with interstage EQ
// ---------------------------------------------------------------
hardFreq =
    tune
  + mix(165,255,punch)*pitchFast(mix(0.0085,0.0048,punch))
  + mix(92,152,0.50*body+0.50*punch)*pitchBody(mix(0.046,0.078,body));

hardPhase = phasor(hardFreq);
// Stage 6.7: HARD remains clipped, but is less saturated than Stage 6.5.
hardDecay = min(0.42,max(0.20,(length/1000.0)*1.30));
hardAmp = ampEnv(hardDecay)
          * (1.0 + mix(0.62,1.20,punch)*transEnv(mix(0.040,0.022,punch)));

hardSource =
   (sub*sineFromPhase(hardPhase,1)
   +mix(0.20,0.40,body)*sineFromPhase(hardPhase,2)
   +mix(0.08,0.25,grit)*sineFromPhase(hardPhase,3)
   +mix(0.025,0.13,destroy)*sineFromPhase(hardPhase,4))*hardAmp
   +mix(0.035,0.15,impact*grit)*sineFromPhase(hardPhase,6)*transEnv(mix(0.026,0.012,punch));

hardStage1 =
    hardSource
  : fi.peak_eq_cq(mix(2.0,6.0,body),mix(92,128,body),0.8)
  : fi.peak_eq_cq(mix(0.5,3.5,grit),mix(240,480,colour),0.8)
  : softNL(mix(1.45,2.65,drive),mix(0.012,0.075,shape));

hardStage2 =
    hardStage1
  : fi.peak_eq_cq(mix(0.5,4.0,impact),mix(115,170,punch),0.9)
  : hardNL(mix(1.02,1.32,destroy))
  : fi.lowpass(3,mix(4800,8200,colour))
  : fi.peak_eq_cq(mix(0.5,4.0,grit),mix(400,800,colour),0.85)
  : hardNL(mix(1.00,1.18,destroy));

hardStage3 = hardStage2
  : fi.peak_eq_cq(mix(-1.5,1.5,shape),mix(700,1200,colour),0.75)
  : hardNL(mix(1.00,1.10,clipper));

hardSig = ba.if(clipper>0.72,hardStage3,hardStage2)
  : fi.high_shelf(mix(-6,-1,colour),3000)
  : fi.lowpass(4,mix(5400,9000,colour))
  : fi.highpass(2,20)
  : softNL(mix(1.03,1.22,drive),0.0);

// ---------------------------------------------------------------
// INDUSTRIAL / SUSTAINED
// ---------------------------------------------------------------
mechRate = mix(15,38,evolve);
mechEnv  = expTauEnv(0.0001,mix(0.24,0.46,body));
mechWarp = mix(3,14,evolve)*os.osc(mechRate)*mechEnv;

industrialFreq =
    tune
  + mix(225,380,punch)*pitchFast(mix(0.011,0.0058,punch))
  + mix(108,172,0.45*body+0.55*punch)*pitchBody(mix(0.058,0.108,body))
  + mechWarp;

industrialPhase = phasor(industrialFreq);
// Stage 6.7: INDUSTRIAL carries the longest dirty/mechanical sustain after ROUND.
industrialDecay = min(0.60,max(0.36,(length/1000.0)*1.80));
industrialAmp = ampEnv(industrialDecay)
                * (1.0 + mix(0.52,1.08,punch)*transEnv(mix(0.050,0.026,punch)));

industrialSource =
   (sub*sineFromPhase(industrialPhase,1)
   +mix(0.18,0.42,body)*sineFromPhase(industrialPhase,2)
   +mix(0.07,0.25,grit)*sineFromPhase(industrialPhase,3))*industrialAmp
   +mix(0.04,0.22,metal)*sineFromPhase(industrialPhase,4)*expTauEnv(0.0001,mix(0.24,0.50,body))
   +mix(0.02,0.12,metal*grit)*sineFromPhase(industrialPhase,5)*expTauEnv(0.0001,mix(0.24,0.50,body))
   +mix(0.025,0.13,impact*metal)*sineFromPhase(industrialPhase,7)*transEnv(mix(0.027,0.013,punch));

industrialSig =
    industrialSource
  : fi.peak_eq_cq(mix(1.5,5.5,body),mix(90,125,body),0.75)
  : softNL(mix(1.45,2.75,drive),mix(0.025,0.125,shape))
  : fi.peak_eq_cq(mix(1.0,6.5,metal),mix(320,720,colour),0.75)
  : hardNL(mix(1.01,1.20,destroy))
  : fi.lowpass(3,mix(5000,8500,colour))
  : softNL(mix(1.01,1.34,drive),mix(0.010,0.045,shape))
  : fi.high_shelf(mix(-5,-0.5,colour),3000)
  : fi.highpass(2,20);

// ---------------------------------------------------------------
// RAVE / BRIGHT — bright attack, dark body
// ---------------------------------------------------------------
raveFreq =
    tune
  + mix(325,560,punch)*pitchFast(mix(0.0058,0.0029,punch))
  + mix(138,245,0.78*punch+0.22*body)*pitchBody(mix(0.030,0.052,body));

ravePhase = phasor(raveFreq);
// Stage 6.7: RAVE has a medium body with a very brief bright saturated attack.
// Stage 6.9: RAVE uses a true percussion AR body instead of another
// instant-full-level exponential kick core.
// Anchor model: ~66 ms rise, ~0.82 s release, plus ~20 ms coherent core transient.
raveBodyAttack = mix(0.050,0.073,body);
raveBodyRelease = min(1.10,max(0.60,(length/1000.0)*3.80));
raveBodyEnv = en.ar(raveBodyAttack,raveBodyRelease,gate);
raveCoreTransient = mix(0.80,0.95,impact)
                  * transEnv(mix(0.024,0.018,punch));
raveAmp = raveBodyEnv + raveCoreTransient;

raveHigh = mix(0.14,0.60,metal*colour);
raveSource =
   (sub*sineFromPhase(ravePhase,1)
   +mix(0.10,0.26,body)*sineFromPhase(ravePhase,2)
   +mix(0.035,0.14,colour)*sineFromPhase(ravePhase,3))*raveAmp
   +(raveHigh*sineFromPhase(ravePhase,5)
   +raveHigh*mix(0.45,0.82,grit)*sineFromPhase(ravePhase,7)
   +raveHigh*mix(0.22,0.52,destroy)*sineFromPhase(ravePhase,9))*transEnv(mix(0.0080,0.0032,punch));

raveClick = no.noise
          : fi.highpass(2,mix(900,1700,colour))
          : fi.lowpass(2,mix(4800,8200,colour))
          : *(mix(0.030,0.19,impact*colour)*transEnv(mix(0.0045,0.0018,punch)));

raveSigCore =
    (raveSource+raveClick)
  : fi.peak_eq_cq(mix(1.5,5.5,impact),mix(105,150,punch),0.85)
  : fi.peak_eq_cq(mix(0.5,5.5,colour),mix(800,1700,colour),0.8)
  : softNL(mix(1.20,1.90,drive),mix(0.004,0.032,shape))
  : hardNL(mix(1.00,1.13,destroy))
  : fi.high_shelf(mix(-2,1.5,colour),3200)
  : fi.lowpass(4,mix(7000,11500,colour))
  : fi.highpass(2,20)
  : softNL(mix(1.05,1.35,drive),0.0);

// Stage 6.10: final RAVE decay contour AFTER creative saturation.
// Stage69B proved that the nonlinear chain lengthens the audible RAVE tail.
// Keep the approved attack/body and explicitly decouple final decay from saturation.
raveTailHold = 0.155;
raveTailNorm = clip01((length-120.0)/480.0);
raveTailTau = mix(0.95,1.65,raveTailNorm);
raveTailBase = expTauEnv(0.00001,raveTailTau);
raveTailTaper = min(1.0,raveTailBase*exp(raveTailHold/raveTailTau));
raveSig = raveSigCore*raveTailTaper;

// ---------------------------------------------------------------
// STAGE 7.1 — USER-APPROVED FAMILY POST PROCESSING
// ---------------------------------------------------------------
// The five core generators above remain intact.
// Stage 7 adds a controlled 105 Hz SUB/BODY split AFTER each family's existing
// character chain. Each family then receives a different treatment before all
// five converge into one common master chain.
//
// The Faust standard library supplies the Butterworth filters and compressor.
// ADAA nonlinearities are used for real-time-safe saturation/clipping.

stage7Sub(x) = x : fi.lowpass(4,105);
stage7Body(x) = x - stage7Sub(x);

stage7Tail(hold,tau) =
    min(1.0,expTauEnv(0.00001,tau)*exp(hold/tau));

// Stage 7.1B compile fix.
// All Stage 7 saturation drives are constants, so their hyperbolic-tangent
// normalization values are precomputed. This removes the ambiguous bare
// maths-library identifier without changing the intended normalization.
//
// 1.10 -> 0.800499021761
// 1.08 -> 0.793199097084
// 1.65 -> 0.928857621455
// 1.55 -> 0.913785490118
// 1.14 -> 0.814414093766
// 1.55 * 0.045 -> 0.069637106984

stage7SatNorm(d,norm,x) =
    softNL(d,0.0,x) / max(0.000001,norm);

stage7SoftMix(d,norm,m,x) =
    (1.0-m)*x + m*stage7SatNorm(d,norm,x);

stage7BiasSatNorm(d,b,dc,norm,x) =
    (((x+b)*d : aa.tanh1) - dc)
    / max(0.000001,norm);

stage7BiasSoftMix(d,b,dc,norm,m,x) =
    (1.0-m)*x + m*stage7BiasSatNorm(d,b,dc,norm,x);

stage7HardAt(c,x) =
    ((x/c) : aa.hardclip) * c;

// ROUND — long clean sub, restrained body saturation.
stage7Round(x) =
      stage7Sub(x)*stage7Tail(0.120,0.720)
    + (stage7Body(x)
       : stage7SoftMix(1.10,0.800499021761,0.16)
       : fi.peak_eq_cq(-0.4,190,0.85)
       : fi.highpass(2,95));

// PUNCH — shortest sub, short coherent upper transient, minimal saturation.
stage7Punch(x) =
      stage7Sub(x)*stage7Tail(0.050,0.180)
    + ((0.98*stage7Body(x)
        +0.09*(stage7Body(x)
               : fi.highpass(2,900))
              *expTauEnv(0.00001,0.018))
       : stage7SoftMix(1.08,0.793199097084,0.08)
       : fi.highpass(2,100));

// HARD — sub kept out of the clipped body path.
stage7Hard(x) =
      stage7Sub(x)*stage7Tail(0.090,0.280)
    + (stage7Body(x)
       : fi.peak_eq_cq(2.0,850,0.90)
       : stage7SoftMix(1.65,0.928857621455,0.48)
       : stage7HardAt(0.76)
       : fi.highpass(2,105));

// INDUSTRIAL — short sub, asymmetric mechanical low-mid sustain.
stage7IndustrialMech(x) =
    stage7Body(x)
    : fi.peak_eq_cq(3.0,430,1.00)
    : stage7BiasSoftMix(1.55,0.045,0.069637106984,0.913785490118,0.42)
    : fi.highpass(2,110);

stage7Industrial(x) =
      stage7Sub(x)*stage7Tail(0.070,0.170)
    + ((0.74*stage7Body(x)
        +0.34*(stage7IndustrialMech(x)
               : fi.bandpass(2,180,1800)))
       : fi.highpass(2,105));

// RAVE — short/medium sub, 1.5 kHz body identity, brief bright transient.
stage7Rave(x) =
      stage7Sub(x)*stage7Tail(0.080,0.240)
    + ((0.98*(stage7Body(x)
              : fi.peak_eq_cq(1.5,1500,0.80))
        +0.07*(stage7Body(x)
               : fi.peak_eq_cq(1.5,1500,0.80)
               : fi.highpass(2,1700))
              *expTauEnv(0.00001,0.025))
       : stage7SoftMix(1.14,0.814414093766,0.14)
       : fi.highpass(2,105));

// Static trims reproduce the approved offline PRE-MASTER anchor calibration.
// They are deliberately not adaptive normalizers.
roundStage7 =
    roundSig*0.646326
    : stage7Round
    : *(0.750335);

punchStage7 =
    punchSig*0.654434
    : stage7Punch
    : *(0.691291);

hardStage7 =
    hardSig*0.682907
    : stage7Hard
    : *(0.479674);

industrialStage7 =
    industrialSig*0.484508
    : stage7Industrial
    : *(0.849918);

raveStage7 =
    raveSig*0.801258
    : stage7Rave
    : *(0.667870);

// ---------------------------------------------------------------
// COMMON MASTER — approved Stage 7 direction
// ---------------------------------------------------------------
// Light saturation.
// Glue compressor: 4:1, threshold -9.5 dBFS, attack 30 ms, release 30 ms.
// Creative hard clipper: +2 dB drive, -0.8 dBFS ceiling.
//
// The hard clip is ADAA. The existing JUCE -0.70 dBFS limiter remains emergency
// protection only; it must stay essentially inactive in the technical gate.

stage7MasterSat(x) =
    stage7SoftMix(1.08,0.793199097084,0.18,x);

stage7Glue =
    co.compressor_mono(4,-9.5,0.030,0.030);

stage7ClipCeiling = db2lin(-0.8);
stage7ClipDrive = db2lin(2.0);
stage7MasterHardClip(x) =
    ((x*(stage7ClipDrive/stage7ClipCeiling)) : aa.hardclip)
    *stage7ClipCeiling;

stage7Master(x) =
    x
    : stage7MasterSat
    : stage7Glue
    : stage7MasterHardClip;

// ---------------------------------------------------------------
// STAGE 10.2 — ACCENT LAYER + FILTERED REVERB + PARALLEL FX BUS
// ---------------------------------------------------------------
// User direction after Stage 10.1:
//   - keep the original kick level/processing untouched;
//   - reduce ONLY the added layers;
//   - MUTANT and SUSTAIN slightly lower again;
//   - slightly shorten the wet/bus tail of MUTANT and SUSTAIN;
//   - no second low-frequency kick layer.
//
// AccentBank is an internal (non-host) 0..4 selector persisted by JUCE:
//   0 CORE, 1 TIGHT, 2 HEAVY, 3 SUSTAIN, 4 MUTANT.
//
// IMPORTANT:
// The approved Stage 7 family output + common master is computed first as
// stage10Dry.  New material is then added in parallel.  CORE adds exactly
// zero, so all Stage 7 anchor references remain bit-for-bit on the DSP path.

stage10FamPick(a,b,c,d,e) =
    (a,b,c,d,e) : ba.selectn(5,family);

stage10BankPick(a,b,c,d,e) =
    (a,b,c,d,e) : ba.selectn(5,accentBank);

// ----- deterministic transient / percussion / top-kick / metal sources
stage10ClickFreq = stage10FamPick(2100,3800,2900,1850,4600);
stage10ClickTau  = stage10BankPick(0.0065,0.0035,0.0055,0.0075,0.0058);
stage10ClickPhase = phasor(stage10ClickFreq);
stage10Click =
    (sineFromPhase(stage10ClickPhase,1)
     +0.22*sineFromPhase(stage10ClickPhase,2))
    *expTauEnv(0.0008,stage10ClickTau);

stage10PercFreq = stage10FamPick(360,720,850,520,1050);
stage10PercTau  = stage10BankPick(0.040,0.021,0.080,0.180,0.095);
stage10PercPhase = phasor(stage10PercFreq);
stage10Perc =
    (sineFromPhase(stage10PercPhase,1)
     +0.34*sineFromPhase(stage10PercPhase,1.47)
     +0.15*sineFromPhase(stage10PercPhase,2.12))
    *expTauEnv(0.0015,stage10PercTau);

stage10TopStart = stage10FamPick(300,520,430,360,680);
stage10TopEnd   = stage10FamPick(150,190,165,145,210);
stage10TopTau   = stage10BankPick(0.045,0.025,0.060,0.050,0.042);
stage10TopFreq =
      stage10TopEnd
    + (stage10TopStart-stage10TopEnd)*pitchFast(stage10TopTau);
stage10TopPhase = phasor(stage10TopFreq);
stage10TopEnvTau = stage10BankPick(0.040,0.028,0.098,0.135,0.066);
stage10Top =
    (sineFromPhase(stage10TopPhase,1)
     +0.16*sineFromPhase(stage10TopPhase,2))
    *expTauEnv(0.0008,stage10TopEnvTau);

stage10MetalFreq  = stage10FamPick(650,1200,1100,780,1600);
stage10MetalRatio = stage10FamPick(1.67,1.67,1.67,1.414,1.67);
stage10MetalIndex = stage10FamPick(0.52,0.65,0.975,1.625,1.30);
stage10MetalPhase = phasor(stage10MetalFreq);
stage10MetalMod   = sineFromPhase(phasor(stage10MetalFreq*stage10MetalRatio),1);
stage10Metal =
    sin(2.0*ma.PI*stage10MetalPhase + stage10MetalIndex*stage10MetalMod)
    *expTauEnv(0.0008,stage10BankPick(0.060,0.050,0.070,0.085,0.090));

// MUTANT metal share is deliberately 40% (not the earlier ~70% prototype).
stage10LayerRaw =
    (0.64*stage10Click +0.27*stage10Perc +0.09*stage10Top,
     0.90*stage10Click +0.10*stage10Perc,
     0.28*stage10Perc  +0.72*stage10Top,
     0.72*stage10Perc  +0.20*stage10Top +0.08*stage10Metal,
     0.10*stage10Click +0.33*stage10Perc +0.17*stage10Top +0.40*stage10Metal)
    : ba.selectn(5,accentBank);

stage10LayerHP = stage10BankPick(450,1500,190,320,520);
stage10LayerLPBase = stage10BankPick(6000,9000,2400,3600,4800);
stage10LayerLP =
    stage10LayerLPBase
    *stage10FamPick(0.82,1.00,1.00,1.00,1.08);

stage10LayerFiltered =
    stage10LayerRaw
    : fi.highpass(2,stage10LayerHP)
    : fi.lowpass(2,min(10500,stage10LayerLP));

stage10LayerRound(x) =
    0.86*x + 0.14*stage7SoftMix(1.10,0.800499021761,0.14,x);
stage10LayerPunch(x) =
    0.78*x + 0.22*stage7SoftMix(1.14,0.814414093766,0.22,x);
stage10LayerHard(x) =
    0.70*x + 0.30*stage7HardAt(0.68,x);
stage10LayerIndustrial(x) =
    0.72*x + 0.28*stage7SoftMix(1.55,0.913785490118,0.28,x);
stage10LayerRave(x) =
    0.75*x + 0.25*stage7SoftMix(1.14,0.814414093766,0.25,x);

stage10LayerVoiced =
    (stage10LayerRound(stage10LayerFiltered),
     stage10LayerPunch(stage10LayerFiltered),
     stage10LayerHard(stage10LayerFiltered),
     stage10LayerIndustrial(stage10LayerFiltered),
     stage10LayerRave(stage10LayerFiltered))
    : ba.selectn(5,family);

// Lowered additional layer levels.
// CORE remains 0 to preserve the approved dry anchor exactly.
// SUSTAIN / MUTANT are a little lower again per user feedback.
stage10LayerGain = stage10BankPick(0.0,0.028,0.030,0.016,0.013);
stage10Accent =
    stage10LayerVoiced*stage10LayerGain
    : fi.highpass(4,170);

// ----- original approved kick, completely unchanged
stage10Dry =
    (roundStage7,
     punchStage7,
     hardStage7,
     industrialStage7,
     raveStage7)
    : ba.selectn(5,family)
    : stage7Master;

// ----- bank-specific parallel FX bus; it receives the ORIGINAL kick + accent
stage10BusInput = stage10Dry + 0.35*stage10Accent;

stage10BusCore(x) = 0.0*x;

stage10BusTight(x) =
    x
    : fi.highpass(2,900)
    : fi.lowpass(2,8200)
    : stage7SoftMix(1.14,0.814414093766,0.18)
    : stage7HardAt(0.82);

stage10BusHeavy(x) =
    x
    : fi.highpass(2,180)
    : fi.lowpass(2,1300)
    : co.compressor_mono(6,-20,0.015,0.115)
    : stage7SoftMix(1.10,0.800499021761,0.24);

stage10BusSustain(x) =
    x
    : fi.highpass(2,320)
    : fi.lowpass(2,2300)
    : co.compressor_mono(4,-18,0.012,0.075)
    : stage7SoftMix(1.14,0.814414093766,0.18);

stage10BusMutant(x) =
    x
    : fi.highpass(2,520)
    : fi.lowpass(2,4800)
    : stage7SoftMix(1.55,0.913785490118,0.24);

stage10BusColour =
    (stage10BusCore(stage10BusInput),
     stage10BusTight(stage10BusInput),
     stage10BusHeavy(stage10BusInput),
     stage10BusSustain(stage10BusInput),
     stage10BusMutant(stage10BusInput))
    : ba.selectn(5,accentBank)
    : fi.highpass(4,190);

// Added bus is kept below the original kick.
// SUSTAIN / MUTANT are slightly reduced relative to the previous prototype.
stage10BusGain = stage10BankPick(0.0,0.010,0.012,0.009,0.008);

// ----- filtered ambience from accent + a small send of the effect bus
stage10VerbBusSend = stage10BankPick(0.0,0.04,0.07,0.18,0.15);
stage10VerbInput =
    (stage10Accent + stage10VerbBusSend*stage10BusColour)
    : fi.highpass(4,330)
    : fi.lowpass(2,6800);

// Short mono Freeverb texture.
// SUSTAIN and MUTANT feedback were reduced slightly to shorten their bus tail.
stage10VerbFb1 = stage10BankPick(0.20,0.30,0.38,0.46,0.43);
stage10VerbDamp = stage10BankPick(0.66,0.58,0.61,0.58,0.61);
stage10Verb =
    stage10VerbInput
    : re.mono_freeverb(stage10VerbFb1,0.45,stage10VerbDamp,0)
    : fi.highpass(4,330)
    : fi.lowpass(2,6000);

stage10VerbGain = stage10BankPick(0.0,0.0035,0.0045,0.0065,0.0050);

// No adaptive dry gain / no dry normalization.
// Only parallel material is added to the already-approved kick.
stage10Added =
      stage10Accent
    + stage10BusGain*stage10BusColour
    + stage10VerbGain*stage10Verb;

mono =
    (stage10Dry + stage10Added)
    : *(outGain);

process = mono <: _,_;
