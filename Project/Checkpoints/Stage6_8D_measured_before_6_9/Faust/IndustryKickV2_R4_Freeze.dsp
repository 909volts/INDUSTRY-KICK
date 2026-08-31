
// INDUSTRY KICK V2 — Stage 6.8 audio-parity / safety-headroom candidate
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
punchDecay = min(0.21,max(0.105,(length/1000.0)*0.75));
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
raveDecay = min(0.40,max(0.20,(length/1000.0)*1.45));
// Stage 6.8: RAVE body must not duplicate PUNCH's front-loaded core.
raveAmp = ampEnv(raveDecay)
          * (1.0 + mix(0.20,0.50,punch)*transEnv(mix(0.024,0.012,punch)));

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

raveSig =
    (raveSource+raveClick)
  : fi.peak_eq_cq(mix(1.5,5.5,impact),mix(105,150,punch),0.85)
  : fi.peak_eq_cq(mix(0.5,5.5,colour),mix(800,1700,colour),0.8)
  : softNL(mix(1.20,1.90,drive),mix(0.004,0.032,shape))
  : hardNL(mix(1.00,1.13,destroy))
  : fi.high_shelf(mix(-2,1.5,colour),3200)
  : fi.lowpass(4,mix(7000,11500,colour))
  : fi.highpass(2,20)
  : softNL(mix(1.05,1.35,drive),0.0);

// Stage 6.8: linear post-character headroom.
// The JUCE -0.70 dBFS clamp is emergency safety, not a creative clipping stage.
mono = (roundSig*0.88,
        punchSig*0.88,
        hardSig*0.90,
        industrialSig*0.82,
        raveSig*0.90)
     : ba.selectn(5,family)
     : *(outGain);
process = mono <: _,_;
