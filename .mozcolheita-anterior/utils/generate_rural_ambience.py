import math, random, wave, array
from pathlib import Path
rng=random.Random(2646)
rate=22050;duration=24
samples=array.array('h');wind=0.0
# Original synthesised wind, insects and distant bird chirps, with a quiet loop seam.
for i in range(rate*duration):
 t=i/rate;wind=wind*.975+rng.uniform(-1,1)*.025
 edge=min(1,t/1.5,(duration-t)/1.5)
 value=wind*.16
 for offset in (2.0,6.3,11.0,17.1,20.5):
  u=t-offset
  if 0<u<1.1:
   pulse=max(0,math.sin(u*math.pi*4))**3*math.sin(math.pi*u/1.1)**2
   value+=.028*pulse*math.sin(2*math.pi*(1700*u+450*u*u+20*math.sin(18*u)))
 value+=.003*math.sin(2*math.pi*3700*t)*max(0,math.sin(2*math.pi*32*t))*(.6+.4*math.sin(t*.8))
 samples.append(int(max(-1,min(1,value*edge))*32767))
output = Path(__file__).resolve().parents[1] / 'Assets/Audio/rural_day.wav'
with wave.open(str(output),'wb') as f:
 f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(samples.tobytes())
