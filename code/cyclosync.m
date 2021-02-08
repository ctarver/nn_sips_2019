function [delay,coeff,synced]=cyclosync(x,y,varargin)

%CYCLOSYNC	Synchronise two cyclic signals
%	[DELAY,COEFF]=CYCLOSYNC(X,Y) finds the delay DELAY and complex 
%	coefficient COEFF (which accounts for gain and constant phase shift) 
%	to be applied to signal vector Y to synchronise with signal X. X and 
%	Y must be the same length, and are assumed to be one period of a 
%	periodic signal. In time domain, the corresponding continuous-time 
%	signal x(t) approximates COEFF * y(t-DELAY*Ts), where Ts is the 
%	sample interval.
%
%	[DELAY,COEFF,XSYNC]=CYCLOSYNC(X,Y) also returnes signal X 
%	synchronised to Y, i.e., delayed by -DELAY samples and divided by 
%	COEFF.
%	
%	[DELAY,COEFF,YSYNC]=CYCLOSYNC(X,Y,...,'Y TO X') synchronises Y to X 
%	instead of X to Y by delaying Y by DELAY samples and multiplying 
%	by COEFF, and returns this in YSYNC.
%	
%	
%	By delaying Y by DELAY samples and multiplying by COEFF, we obtain a 
%	signal synchronised with X. Or, by delaying X by -DELAY samples and 
%	dividing by COEFF, we obtain a signal synchronised with Y.
%	
%	


%	Author:	Vesa Lehtinen (Aug 2012)
%		ext-vesa.k.lehtinen@nokia.com
%		vesa.lehtinen@tut.fi



x=x(:);
y=y(:);

%----------.
% Defaults |
%----------'

noScaling=true;

sync='X TO Y';
debug_corr=false;
debug_phase=false;

%---------.
% Options |
%---------'
while numel(varargin)
  if ~ischar(varargin{1})
    error 'Optional input args must start with an option name.'
  end
  switch upper(varargin{1})
    case 'NO SCALING'
      noScaling=true;
      varargin(1)=[];
    case {'X TO Y' 'Y TO X'}
      sync=varargin{1};
      varargin(1)=[];
    case 'DEBUG:CORR'
      debug_corr=true;
      varargin(1)=[];
    case 'DEBUG:PHASE'
      debug_phase=true;
      varargin(1)=[];
    otherwise
      error('Unknown option "%s".',varargin{1})
  end % switch
end % while

N=numel(x);
if N ~= numel(y)
  error 'Signals must be the same length.'
end

f=[0:ceil(N/2)-1 -floor(N/2):-1]';

X=fft(x);
Y=fft(y);

XY=X.*conj(Y);
xya=abs(ifft(XY));
delayInt=min(find(xya==max(xya)))-1;
if debug_corr
  clf
  plot(0:N-1,xya)
  hold on
  plot([0 0]+delayInt,ylim,'m')
  hold off
  drawnow
  shg
  %%%%pause
end % if debug_corr


if 0
  %------------------------------.
  % Sync by interpolator fitting |
  %------------------------------'

  yd = y(1+mod((0:end-1)-delayInt, end));
  
  % yd ~ x + dx.*polyval(p1,n) + ddx.*polyval(p2,n) + dddx.*polyval(p3,n)
  % yd-x ~ [dx dx.*n... ddx ddx.*n... dddx dddx.*n...] * [p1 p2 p3]'
  
  n = (0:N-1)'-(N-1)/2;
  w = 2*pi*[0:ceil(N/2)-1 -floor(N/2):-1]'/N;
  pb = abs(w) <= 2*pi*1.02*28e6/81.6e6;
  dx = ifft(1j*w.*pb.*X);
  ddx = ifft(-w.^2.*pb.*X);
  dddx = ifft(-1j*w.^3.*pb.*X);
  
  if 0
    I=2:N-1;
  else
    I=1:N;
  end
  den = [dx n.*dx ddx n.*ddx n.^2.*ddx dddx n.*dddx n.^2.*dddx n.^3.*dddx];
  c = [real(den(I,:)); imag(den(I,:))] \ [real(yd(I)-x(I)); imag(yd(I)-x(I))]
  
  xBeforeFit = x;
  x = x + den * c;
  X = fft(x);
  
  if 01
    cla
    plot(abs(x-yd))
    axis tight
    ylim auto
    title 'cyclosync: interpolator fitting'
    if 0
      beep
      pause
    else
      drawnow
    end
  end
  
  %error 'Sync by parameter fitting--UNIMPLEMENTED!'

else
  xBeforeFit = [];
end

rot=@(n,x) 1+mod(n-1,numel(x));


p=polyfit((-2:2)',xya(rot(1+delayInt+(-2:2),xya)),4);
% Differentiate:
pd=(4:-1:1).*p(1:4);
% Find extrema:
rt=roots(pd);
% Remove invalid roots:
rt(~~imag(rt) | rt<=-1 | rt>=1)=[];
if isempty(rt)
  rt=0;
end

% Make sure there's only one root left, the one 
% that yields the highest polynomial value:
pVal=polyval(p,rt);
rt=rt(min(find(pVal==max(pVal))));


% The total delay:
delay=mod(delayInt+rt,N);
closestDelay=delay-N*round(delay/N);

if debug_corr
  hold on7
  plot([0 0]+delay,ylim,'r',delayInt+(-2:0.01:2),polyval(p,-2:0.01:2),'g')
  hold off
  drawnow
  shg
  pause
end % if debug_corr


switch upper(sync)

   case 'X TO Y'
     synced=X.*exp(1j*2*pi*closestDelay*f/N);
     if 01
       fineDelay = -median(diff(angle(synced)-angle(Y)))/(2*pi);
       delay=delay+fineDelay;
       closestDelay=delay-N*round(delay/N);
       if abs(fineDelay) > 0.1
         warning 'Fine delay estimation failed.'
	 fineDelay=0;
       else
         synced=synced.*exp(1j*2*pi*fineDelay*f/N);
       end % if
     end % if 0[1]
     coeff = Y \ synced;
     if noScaling
       coeff=coeff/abs(coeff);
     end
     synced=ifft(synced/coeff);
     
   case 'Y TO X'
     synced=Y.*exp(-1j*2*pi*closestDelay*f/N);
     if 01
       fineDelay = -median(diff(angle(X)-angle(synced)))/(2*pi);
       delay=delay+fineDelay;
       closestDelay=delay-N*round(delay/N);
       if abs(fineDelay) > 0.1
         warning 'Fine delay estimation failed.'
	 fineDelay=0;
       else
         synced=synced.*exp(-1j*2*pi*fineDelay*f/N);
       end % if
     end % if 0[1]
     coeff = synced \ X;
     if noScaling
       coeff=coeff/abs(coeff);
     end
     synced=ifft(coeff*synced);

   otherwise
     error 'BUG!'

end % switch sync

if debug_phase
  switch sync
   case 'X TO Y'
     plot(conj(Y).*synced)
   case 'Y TO X'
     plot(conj(synced).*X)
  end % switch
  axis tight
  axis equal
  hold on
  im=1j * 1e-6 * coeff * ~imag(coeff);  % Ensure complex plotting:
  plot([0 (coeff+im)/abs(coeff)*max(abs([xlim ylim]))],'r','LineWidth',3)
  hold off
  axis tight
  axis equal
  shg
  pause
end % if debug_phase
