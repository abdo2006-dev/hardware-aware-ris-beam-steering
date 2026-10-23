function h=ris_sha256(file)
f=fopen(file,'rb');assert(f>=0,'Cannot open source file.');cleanup=onCleanup(@()fclose(f));
b=fread(f,Inf,'*uint8');
% R2026b installation has no Java runtime. Windows .NET hashing needs no JRE.
d=System.Security.Cryptography.SHA256.Create();cleanupHash=onCleanup(@()d.Dispose()); %#ok<NASGU>
digest=uint8(d.ComputeHash(b));h=lower(reshape(dec2hex(digest,2).',1,[]));
end
