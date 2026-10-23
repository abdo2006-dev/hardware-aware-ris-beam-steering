"""Approximate color-curve digitization of the supplied paper, PDF page 3.

Run with --pdf <licensed local copy> --pdftoppm <Poppler executable>.
No PDF or rendered source page is published. Calibration is specific to this
5-page IEEE version and must be visually checked for a different PDF layout.
"""
import argparse,hashlib,json,pathlib,subprocess,tempfile
import numpy as np
import pandas as pd
from PIL import Image

def main():
    p=argparse.ArgumentParser();p.add_argument('--pdf',type=pathlib.Path,required=True)
    p.add_argument('--pdftoppm',required=True);a=p.parse_args()
    root=pathlib.Path(__file__).resolve().parents[1];out=root/'data'/'paper_digitized_reference';out.mkdir(exist_ok=True,parents=True)
    temp=root/'tmp';temp.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(dir=temp) as td:
        prefix=str(pathlib.Path(td)/'page3')
        proc=subprocess.run([a.pdftoppm,'-f','3','-l','3','-singlefile','-scale-to-x','1191','-scale-to-y','1684','-png',str(a.pdf),prefix],check=True,capture_output=True,text=True)
        (temp/'paper_render_diagnostics.txt').write_text(proc.stderr)
        png=pathlib.Path(prefix+'.png');im=np.asarray(Image.open(png).convert('RGB'))
        assert im.shape[:2]==(1684,1191)
        calibration={'magnitude':dict(x0=690,x1=1073,y0=110,y1=321,v0=1,v1=.65),
                     'phase':dict(x0=697,x1=1063,y0=381,y1=592,v0=200,v1=-200)}
        curves={};pixel_counts={}
        for quantity,c in calibration.items():
            for state,color in [(0,'red'),(1,'blue')]:
                xs=[];ys=[]
                for x in range(c['x0']+1,c['x1']):
                    col=im[c['y0']+1:c['y1'],x]
                    if color=='red':mask=(col[:,0]>150)&(col[:,1]<120)&(col[:,2]<120)
                    else:mask=(col[:,2]>150)&(col[:,0]<120)&(col[:,1]<130)
                    yy=np.flatnonzero(mask)+c['y0']+1
                    # Exclude legend rectangles and their colored line samples.
                    if quantity=='magnitude' and 982<=x<=1063:yy=yy[(yy<143)|(yy>179)]
                    if quantity=='phase' and 930<=x<=1011:yy=yy[(yy<393)|(yy>435)]
                    if len(yy):
                        # Exclude the drawn vertical phase-wrap line.
                        if quantity=='phase' and np.ptp(yy)>20:continue
                        xs.append(x);ys.append(float(np.median(yy)))
                f=24+(np.array(xs)-c['x0'])*6/(c['x1']-c['x0'])
                v=c['v0']+(np.array(ys)-c['y0'])*(c['v1']-c['v0'])/(c['y1']-c['y0'])
                if quantity=='phase':v=np.rad2deg(np.unwrap(np.deg2rad(v)))
                curves[(quantity,state)]=(f,v);pixel_counts[quantity+'_'+color]=len(f)
        fs=np.unique(np.r_[np.arange(24.1,29.91,.1),26.168]);rows=[]
        for state in [0,1]:
            fm,vm=curves[('magnitude',state)];fp,vp=curves[('phase',state)]
            assert min(fs)>=max(min(fm),min(fp)) and max(fs)<=min(max(fm),max(fp))
            mag=np.interp(fs,fm,vm);phase=np.interp(fs,fp,vp)
            for f,m,ph in zip(fs,mag,phase):
                z=m*np.exp(1j*np.deg2rad(ph));rows.append(dict(frequency_GHz=f,state=state,real=z.real,imag=z.imag,magnitude=m,phase_unwrapped_deg=ph,validation_status='PROVISIONAL',source='Goshu et al. Fig.2 approximate color-curve digitization'))
        T=pd.DataFrame(rows);T.to_csv(out/'reflection_states.csv',index=False)
        manifest={'dataset':'paper_digitized_reference','validation_status':'PROVISIONAL',
                  'source':'Goshu et al., Realistic Evaluation of Impedance-Based RIS Modeling, EuCAP 2025, Fig.2, supplied 5-page PDF',
                  'source_pdf_sha256':hashlib.sha256(a.pdf.read_bytes()).hexdigest(),
                  'rendered_page_sha256':hashlib.sha256(png.read_bytes()).hexdigest(),
                  'generator':'tools/digitize_figure2.py','page':3,'render_size_pixels':[1191,1684],
                  'calibration':calibration,'curve_pixel_columns':pixel_counts,
                  'method':'Threshold red/blue pixels, exclude legend and vertical wrap, median row per column, unwrap phase, linearly resample separate plotted magnitude and unwrapped phase; form complex coefficients. Subsequent frequency interpolation uses real/imaginary components.',
                  'estimated_reading_resolution':'About 0.02 GHz horizontally, 0.004 magnitude, 2 degrees phase; estimated raster resolution only, not a statistical confidence interval. Axis registration and original plotting introduce additional unknown error.',
                  'endpoints':'24.0 and 30.0 GHz omitted to avoid clipped curve/axis overlap',
                  'state_mapping':{'0':'ON red','1':'OFF blue'},
                  'supersedes':'Historical approximate single-point states 0.96@38deg and 0.74@-156deg; preserved in historical_approx_point'}
        (out/'manifest.json').write_text(json.dumps(manifest,indent=2))
        print(T[np.isclose(T.frequency_GHz,26.168)].to_string(index=False))
if __name__=='__main__':main()
