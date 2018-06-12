function b = fn_dodebug

hostlist = {'PCWIN-PCT_HP8570P_EQB', 'PCWIN-DESKTOP-CR6ES64'};
b = fn_ismemberstr(fn_hostname,hostlist);
