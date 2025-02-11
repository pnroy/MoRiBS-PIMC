c 20130227 TZ add H^2 estimator to calculate heat capacity of the rotor
      program asymrho_driver
      implicit double precision(a-h,o-z)

      character argum*30

      call getarg(1,argum)
      read(argum,*)temprt
      call getarg(2,argum)
      read(argum,*)nslice
      call getarg(3,argum)
      read(argum,*)iodevn
      call getarg(4,argum)
      read(argum,*)ithini
      call getarg(5,argum)
      read(argum,*)ithfnl
      call getarg(6,argum)
      read(argum,*)Arot
      call getarg(7,argum)
      read(argum,*)Brot
      call getarg(8,argum)
      read(argum,*)Crot
      call getarg(9,argum)
      read(argum,*)maxj

      if(maxj.gt.876) stop 'maxj is larger than the limit of 876'

      maxd=2*maxj+1
      call asymrho(temprt,nslice,iodevn,ithini,ithfnl,Arot,
     +                   Brot,Crot,maxj,maxd)

      end
c----------------------------------------------------------------------
      subroutine asymrho(temprt,nslice,iodevn,ithini,ithfnl,Arot,
     +                   Brot,Crot,maxj,maxd)
c     program asymrho
      implicit double precision(a-h,o-z)

      parameter(pi=3.14159265358979323846d+00,eps=1.d-16)
      parameter(zero=0.d0)
      parameter(boltz=0.6950356d0)
c ... maxd=2*maxj+1,maxfac can't be too large
c     parameter(maxj=100,maxd=201,maxfac=170)
      parameter(maxfac=1754)
c     parameter(maxj=68,maxd=137,maxfac=180)
c     parameter(maxj=100,maxd=201,maxfac=300)
c     parameter(maxj=3,maxd=7,maxfac=170)
      dimension H(maxd,maxd),eigval(maxd),work(maxd)
      dimension engevn((maxj+1)*(maxj+1)),engodd((maxj+1)*(maxj+1)),
     +          eigevn((4*maxj*maxj*maxj+12*maxj*maxj+11*maxj+3)/3),
     +          eigodd((4*maxj*maxj*maxj+12*maxj*maxj+11*maxj+3)/3),
     +          esort((maxj+1)*(maxj+1)),rhopro(0:181*361*361-1),
     +          erotpr(0:181*361*361-1),erotsq(0:181*361*361-1),
     +          dlist(0:maxj,-maxj:maxj,-maxj:maxj,0:180)
      real*16 fact(0:maxfac)
      character argum*30,chrjob*1,uplo*1
      parameter(increm=1)
      dimension awork(10*maxd)

c     write(6,'(''read in temperature and # of slices'')')
c     read(5,*)temprt,nslice
c     temprt=120.d0
c     nslice=1

      chrjob='V'
      UPLO='U'
      lwork=10*maxd

c ... read arguments temprt, nslice, iodevn
c     call getarg(1,argum)
c     read(argum,*)temprt
c     call getarg(2,argum)
c     read(argum,*)nslice
c     call getarg(3,argum)
c     read(argum,*)iodevn
c     call getarg(4,argum)
c     read(argum,*)ithini
c     call getarg(5,argum)
c     read(argum,*)ithfnl
c     call getarg(6,argum)
c     read(argum,*)Arot
c     call getarg(7,argum)
c     read(argum,*)Brot
c     call getarg(8,argum)
c     read(argum,*)Crot

c ... safety check for iodevn
      if(iodevn.gt.1.or.iodevn.lt.-1) then
        write(6,*)'iodevn can only be -1 0 1'
        stop
      endif

c ... calculate tau
      beta=1.d0/(boltz*temprt)
      tau=beta/dfloat(nslice)
      write(6,'(''tau='',f10.5)')tau


c ... calculate factorial
      call calfac(fact,maxfac)

c ... prepare the list of wigner d function
      do j=0,maxj
        do m=-j,j
          do k=-j,j
            do ith=ithini,ithfnl
              th=dfloat(ith)*pi/180.d0
              dlist(j,m,k,ith)=wigd(j,m,k,th,maxfac,fact)
            enddo
          enddo
        enddo
      enddo

c     read(5,*)j,m,k,theta
c     theta=theta*Pi/180.d0


c     stop

      j=0
      nstev=0
      nstod=0
      ivec=0
      jvec=0
   10 continue
      irow=0
      if(mod(j,2).eq.0) then
        kevnst=-j
        koddst=-j+1
        ndimev=j+1
        ndimod=j
      else
        kevnst=-j+1
        koddst=-j
        ndimev=j
        ndimod=j+1
      endif
c ... treating even k
      do k=kevnst,j,2
        irow=irow+1
        jcol=0
        do kp=kevnst,k,2
          jcol=jcol+1
          elemnt=rotmat(j,k,kp,Arot,Brot,Crot)
          H(irow,jcol)=elemnt
          H(jcol,irow)=elemnt
        enddo
      enddo
      if(ndimev.ne.irow)stop'wrong dimension'
      if(j.le.2) then
        write(6,'(/''rotational matrix for even k:''/)')
        do irow=1,ndimev
          write(6,'(3x,10f9.4)')(H(irow,jcol),jcol=1,ndimev)
        enddo
      endif

c     call tql(maxd,ndimev,H,eigval,work)
      call dsyev(chrjob,uplo,ndimev,H,maxd,eigval,awork,lwork,info)

      if(j.le.2) then
        write(6,'(/3x,10f9.4)')(eigval(i),i=1,ndimev)
        write(6,*)
        k=kevnst
        do irow=1,ndimev
          write(6,'(i3,10f9.4)')k,(H(irow,jcol),jcol=1,ndimev)
          k=k+2
        enddo
      endif

c ... calculate overlap matrix
c     do irow=1,ndim
c       do jcol=1,ndim
c         summ=0.d0
c         do kk=1,ndim
c           summ=summ+H(kk,irow)*H(kk,jcol)
c         enddo
c         write(6,*)irow,jcol,summ
c       enddo
c     enddo

c ... store the eigen energies and eigenvectors for the even k
      do ist=1,ndimev
        nstev=nstev+1
        engevn(nstev)=eigval(ist)
        ibs=0
c       write(6,*)j,ist,ivec,engrot(iestot)
        do k=kevnst,j,2
          ibs=ibs+1
          ivec=ivec+1
          eigevn(ivec)=H(ibs,ist)
        enddo
      enddo

c ... treating odd k
      if(j.eq.0) goto 15
      irow=0
      do k=koddst,j,2
        irow=irow+1
        jcol=0
        do kp=koddst,k,2
          jcol=jcol+1
          elemnt=rotmat(j,k,kp,Arot,Brot,Crot)
          H(irow,jcol)=elemnt
          H(jcol,irow)=elemnt
        enddo
      enddo
      if(ndimod.ne.irow) then
        write(6,*)ndimod,irow
        stop'wrong dimension'
      endif
      if(j.le.2) then
        write(6,'(/''rotational matrix for odd k:''/)')
        do irow=1,ndimod
          write(6,'(3x,10f9.4)')(H(irow,jcol),jcol=1,ndimod)
        enddo
      endif

c     call tql(maxd,ndimod,H,eigval,work)
      call dsyev(chrjob,uplo,ndimod,H,maxd,eigval,awork,lwork,info)

      if(j.le.2) then
        write(6,'(/3x,10f9.4)')(eigval(i),i=1,ndimod)
        write(6,*)
        k=koddst
        do irow=1,ndimod
          write(6,'(i3,10f9.4)')k,(H(irow,jcol),jcol=1,ndimod)
          k=k+2
        enddo
      endif

c ... store the eigen energies and eigenvectors for the odd k
      do ist=1,ndimod
        nstod=nstod+1
        engodd(nstod)=eigval(ist)
        ibs=0
c       write(6,*)j,ist,ivec,engrot(iestot)
        do k=koddst,j,2
          ibs=ibs+1
          jvec=jvec+1
          eigodd(jvec)=H(ibs,ist)
        enddo
      enddo

   15 continue

      j=j+1
c     emax=eigval(ndim)
c     write(6,*)exp(-emax*tau),j-1
c     if(exp(-emax*tau).gt.eps.and.j.lt.(maxj+1))goto 10
      if (j.le.maxj) goto 10

      jmax=j-1
      nvecev=ivec
      nvecod=jvec
c ... safety check
c     if(nstev.gt.(maxj+1)*(maxj+1).or.nstod.gt.(maxj+1)*(maxj+1)) then
c       write(6,'(/''!!! TOO MANY STATES'',3I6)')nstev,nstod,
c    +         (maxj+1)*(maxj+1)
c       stop
c     endif
c     if(numst.ne.(jmax+1)*(jmax+1)) then
c       write(6,'(/''!!! WRONG NO. OF STATES''2I6)')
c    +        numst,(jmax+1)*(jmax+1)
c       stop
c     endif
c     if(numcef.gt.(4*maxj*maxj*maxj+12*maxj*maxj+11*maxj+3)/3) then
c       write(6,'(/''!!! TOO MANY COEFFICIENTS'',2I6)'),numcef,
c    +        (4*maxj*maxj*maxj+12*maxj*maxj+11*maxj+3)/3
c       stop
c     endif
c     if(numcef.ne.(4*jmax*jmax*jmax+12*jmax*jmax+11*jmax+3)/3) then
c       write(6,'(/''!!! TOO MANY COEFFICIENTS'',2I6)'),numcef,
c    +        (4*jmax*jmax*jmax+12*jmax*jmax+11*jmax+3)/3
c       stop
c     endif
      write(6,*)'jmax=',jmax

c ... get the highest energy
      do ist=1,nstev
        esort(ist)=engevn(ist)
      enddo
      do ist=1,nstod
        esort(ist+nstev)=engodd(ist)
      enddo
      nsttot=nstev+nstod
      call bubble_sort(esort,nsttot)
      emax=esort(nsttot)
c     write(6,*)'emax=',emax
c ... judge whether the highest energy state has negligible contribution
c ... to the density
      rho=exp(-beta*emax)
      write(6,*)'emax=',emax,' exponential=',rho
      if(rho.gt.1.d-8)stop'too large contribution from emax'
      rho=exp(-tau*emax)
      write(6,*)'emax=',emax,' exponential=',rho
      if(rho.gt.1.d-8)stop'too large contribution from emax'


c ... calculate partition function for the even and odd k states individually
      zparev=zero
      zparod=zero
      eavrev=zero
      eavrod=zero
      esqevn=zero
      esqodd=zero
      istevn=0
      istodd=0
      do j=0,jmax
        if(mod(j,2).eq.0) then
          ndimev=j+1
          ndimod=j
        else
          ndimev=j
          ndimod=j+1
        endif
        ndegen=2*j+1
c ...   sum even k states
        sumevn=zero
        sengev=zero
        seevsq=zero
        do ievnst=1,ndimev
          energy=engevn(istevn+ievnst)
          sumevn=sumevn+exp(-beta*energy)
          sengev=sengev+energy*exp(-beta*energy)
          seevsq=seevsq+energy*energy*exp(-beta*energy)
        enddo
        zparev=zparev+ndegen*sumevn
        eavrev=eavrev+ndegen*sengev
        esqevn=esqevn+ndegen*seevsq
        istevn=istevn+ndimev
c ...   sum odd states
        sumodd=zero
        sengod=zero
        seodsq=zero
        do ioddst=1,ndimod
          energy=engodd(istodd+ioddst)
          sumodd=sumodd+exp(-beta*energy)
          sengod=sengod+energy*exp(-beta*energy)
          seodsq=seodsq+energy*energy*exp(-beta*energy)
        enddo
        zparod=zparod+ndegen*sumodd
        eavrod=eavrod+ndegen*sengod
        esqodd=esqodd+ndegen*seodsq
        istodd=istodd+ndimod
      enddo
      eavrcl=eavrev+eavrod
      esqcla=esqevn+esqodd
      eavrev=eavrev/zparev
      eavrod=eavrod/zparod
      esqevn=esqevn/zparev
      esqodd=esqodd/zparod
      cvevn=(esqevn-eavrev*eavrev)/(boltz*boltz*temprt*temprt)
      cvodd=(esqodd-eavrod*eavrod)/(boltz*boltz*temprt*temprt)
      write(6,'(/''AT BETA'')')
      write(6,'(''EVEN K:    Z='',F12.6,'' E='',F12.6,'' CM-1'',
     +       '' E='',F12.6,'' K'','' Cv='',F12.6,'' Kb'')')
     +       zparev,eavrev,eavrev/boltz,cvevn
      write(6,'(''ODD  K:    Z='',F12.6,'' E='',F12.6,'' CM-1'',
     +       '' E='',F12.6,'' K'','' Cv='',F12.6,'' Kb'')')
     +       zparod,eavrod,eavrod/boltz,cvodd
c ... classical values
      zparcl=zparev+zparod
      eavrcl=eavrcl/zparcl
      esqcla=esqcla/zparcl
      cvcla=(esqcla-eavrcl*eavrcl)/(boltz*boltz*temprt*temprt)
      write(6,'(''CLASSICAL: Z='',F12.6,'' E='',F12.6,'' CM-1'',
     +       '' E='',F12.6,'' K'','' Cv='',F12.6,'' Kb'')')
     +       zparcl,eavrcl,eavrcl/boltz,cvcla

c ... calculate partition function for the even and odd k states individually
c ... for high temperature tau
      zparev=zero
      zparod=zero
      eavrev=zero
      eavrod=zero
      istevn=0
      istodd=0
      do j=0,jmax
        if(mod(j,2).eq.0) then
          ndimev=j+1
          ndimod=j
        else
          ndimev=j
          ndimod=j+1
        endif
        ndegen=2*j+1
c ...   sum even k states
        sumevn=zero
        sengev=zero
        do ievnst=1,ndimev
          energy=engevn(istevn+ievnst)
          sumevn=sumevn+exp(-tau*energy)
          sengev=sengev+energy*exp(-tau*energy)
        enddo
        zparev=zparev+ndegen*sumevn
        eavrev=eavrev+ndegen*sengev
        istevn=istevn+ndimev
c ...   sum odd states
        sumodd=zero
        sengod=zero
        do ioddst=1,ndimod
          energy=engodd(istodd+ioddst)
          sumodd=sumodd+exp(-tau*energy)
          sengod=sengod+energy*exp(-tau*energy)
        enddo
        zparod=zparod+ndegen*sumodd
        eavrod=eavrod+ndegen*sengod
        istodd=istodd+ndimod
      enddo
      eavrcl=eavrev+eavrod
      eavrev=eavrev/zparev
      eavrod=eavrod/zparod
      write(6,'(/,''AT TAU'')')
      write(6,'(''EVEN K:    Z='',F12.6,'' E='',F12.6,'' CM-1'',
     +       '' E='',F12.6,'' K'')')
     +       zparev,eavrev,eavrev/boltz
      write(6,'(''ODD  K:    Z='',F12.6,'' E='',F12.6,'' CM-1'',
     +       '' E='',F12.6,'' K'')')
     +       zparod,eavrod,eavrod/boltz
c ... classical values
      zparcl=zparev+zparod
      eavrcl=eavrcl/zparcl
      write(6,'(''CLASSICAL: Z='',F12.6,'' E='',F12.6,'' CM-1'',
     +       '' E='',F12.6,'' K'')')
     +       zparcl,eavrcl,eavrcl/boltz

c     stop'temporary stop'

c ... calculate density matrix

      do 60 ithe=ithini,ithfnl
 
      do ich=1,30
        argum(ich:ich)=' '
      enddo

      if(ithe.lt.10) then
         write(argum,'(a,i1)')'rho.den00',ithe
      elseif(ithe.ge.10.and.ithe.le.99) then
         write(argum,'(a,i2)')'rho.den0',ithe
      elseif(ithe.gt.99.and.ithe.le.180) then
         write(argum,'(a,i3)')'rho.den',ithe
      else
         write(6,*)'weird ithe',ithe
         stop
      endif

      lenarg=lastch(argum,30)

      write(6,'(a)')argum(1:lenarg)
c     goto 60

c ... file 2 stores the regular output table
      open(2,file=argum(1:lenarg),status='unknown')

c ... file 3 stores the rotational propagator in the data block format
      open(3,file=argum(1:lenarg)//'_rho',status='unknown')
c ... file 4 stores the rotational energy estimator in the data block format
      open(4,file=argum(1:lenarg)//'_eng',status='unknown')
c ... file 7 stores the energy square estimator in the data block format
      open(7,file=argum(1:lenarg)//'_esq',status='unknown')

      if(ithe.eq.0) then
        write(2,'(''# T='',f10.5,'' NSLICE='',I5,'' IODEVN='',I5)')
     +      temprt,nslice,iodevn
        write(2,'(a)')'# the  phi  chi       rho            engrot'
      endif

      theta=dfloat(ithe)*pi/180.d0
c     do 20 iphi=0,360,1
      do 20 iphi=0,360,increm
      write(6,*)iphi
      phi=dfloat(iphi)*pi/180.d0
c     do 30 ichi=0,360,1
      if(iphi.ge.0.and.iphi.le.90) then
        maxchi=iphi
      elseif(iphi.gt.90.and.iphi.le.180) then
        maxchi=180-iphi
      elseif(iphi.gt.180.and.iphi.le.270) then
        maxchi=iphi-180
      else
        maxchi=360-iphi
      endif
      do 30 ichi=0,maxchi,increm

      chi=dfloat(ichi)*pi/180.d0

c ... calculate the rotational density and energy for the even k states

      rhoevn=0.d0
      rhoodd=0.d0
      rotevn=0.d0
      rotodd=0.d0
      esqevn=0.d0
      esqodd=0.d0

      if(iodevn.eq.1) goto 50

      istevn=0
      ivec=0
      do j=0,jmax
c       write(6,*)
        if(mod(j,2).eq.0) then
          kevnst=-j
          ndimev=j+1
        else
          kevnst=-j+1
          ndimev=j
        endif
        pre=dfloat(2*j+1)/(8.d0*pi*pi)
c       write(6,*)'pre=',pre
        rho1=0.d0
        erot1=0.d0
        esq1=0.d0
        do ist=1,ndimev
          istevn=istevn+1
          energy=engevn(istevn)
          expo=exp(-tau*energy)
c         write(6,*)'iestot=',iestot,'ivec=',ivec
          if(expo*pre.lt.eps)goto 40
c         write(6,*)'j=',j,'ist=',ist,'expo=',expo,'rho1=',rho1,
c    +              'rho2=',rho2,'rho3=',rho3,'rho=',rho
c         write(6,*)j,ist,ivec,energy
          im=0
          rho2=0.d0
          do m=kevnst,j,2
            im=im+1
            coef1=eigevn(im+ivec)
            ik=0
            rho3=0.d0
c           write(6,*)'coef1=',coef1
            do k=kevnst,j,2
              ik=ik+1
              coef2=eigevn(ik+ivec)
              rho3=rho3+coef2*dlist(j,m,k,ithe)*
     +                        cos(dfloat(m)*phi+dfloat(k)*chi)
            enddo
c           write(6,*)coef2,rho3
            rho2=rho2+coef1*rho3
          enddo
          rho1=rho1+rho2*expo
          erot1=erot1+expo*rho2*energy
          esq1=esq1+expo*rho2*energy*energy
   40     continue
          ivec=ivec+ndimev
        enddo
        rhoevn=rhoevn+pre*rho1
        rotevn=rotevn+pre*erot1
        esqevn=esqevn+pre*esq1
      enddo

c ... scale the rotational energy contribution by the density
      if(abs(rhoevn).gt.1.0d-16) then
        rotevn=rotevn/rhoevn
        esqevn=esqevn/rhoevn
      else
        rotevn=0.d0
        esqevn=0.d0
      endif

c     write(2,'(3(1x,f15.8))')phi,chi,rho
c ... index formula for rhopro and erotpr: ithe*361*361+iphi*361+ichi
      if(iodevn.eq.0) then
        ind1=ithe*361*361+iphi*361+ichi
        rhopro(ind1)=rhoevn
        erotpr(ind1)=rotevn
        erotsq(ind1)=esqevn
        goto 30
      endif

   50 continue
c     if(iodevn.eq.0)goto 60

c ... calculate the rotational density and energy for the odd k states

      istodd=0
      ivec=0
      do j=0,jmax
c       write(6,*)
        if(mod(j,2).eq.0) then
          koddst=-j+1
          ndimod=j
        else
          koddst=-j
          ndimod=j+1
        endif
        pre=dfloat(2*j+1)/(8.d0*pi*pi)
c       write(6,*)'pre=',pre
        rho1=0.d0
        erot1=0.d0
        esq1=0.d0
        do ist=1,ndimod
          istodd=istodd+1
          energy=engodd(istodd)
          expo=exp(-tau*energy)
c         write(6,*)'iestot=',iestot,'ivec=',ivec
          if(expo*pre.lt.eps)goto 45
c         write(6,*)'j=',j,'ist=',ist,'expo=',expo,'rho1=',rho1,
c    +              'rho2=',rho2,'rho3=',rho3,'rho=',rho
c         write(6,*)j,ist,ivec,energy
          im=0
          rho2=0.d0
          do m=koddst,j,2
            im=im+1
            coef1=eigodd(im+ivec)
            ik=0
            rho3=0.d0
c           write(6,*)'coef1=',coef1
            do k=koddst,j,2
              ik=ik+1
              coef2=eigodd(ik+ivec)
              rho3=rho3+coef2*dlist(j,m,k,ithe)*
     +                        cos(dfloat(m)*phi+dfloat(k)*chi)
            enddo
c           write(6,*)coef2,rho3
            rho2=rho2+coef1*rho3
          enddo
          rho1=rho1+rho2*expo
          erot1=erot1+expo*rho2*energy
          esq1=esq1+expo*rho2*energy*energy
   45     continue
          ivec=ivec+ndimod
        enddo
        rhoodd=rhoodd+pre*rho1
        rotodd=rotodd+pre*erot1
        esqodd=esqodd+pre*esq1
      enddo

c ... scale the rotational energy contribution by the density
      if(abs(rhoodd).gt.1.d-16) then
         rotodd=rotodd/rhoodd
         esqodd=esqodd/rhoodd
      else
         rotodd=0.d0
         esqodd=0.d0
      endif

c     write(2,'(3(1x,f15.8))')phi,chi,rho
      if(iodevn.eq.1) then
        ind1=ithe*361*361+iphi*361+ichi
        rhopro(ind1)=rhoodd
        erotpr(ind1)=rotodd
        erotsq(ind1)=esqodd
        goto 30
      endif

c ... the left over case if for iodevn=-1, the classical case
      rhocla=rhoodd+rhoevn
      rotcla=(rotodd*rhoodd+rotevn*rhoevn)/rhocla
      esqcla=(esqodd*rhoodd+esqevn*rhoevn)/rhocla
      ind1=ithe*361*361+iphi*361+ichi
      rhopro(ind1)=rhoevn+rhoodd
      erotpr(ind1)=(rotodd*rhoodd+rotevn*rhoevn)/(rhoevn+rhoodd)
      erotsq(ind1)=(esqodd*rhoodd+esqevn*rhoevn)/(rhoevn+rhoodd)
c ... remove the possible sigularity at zero probability place
      if(abs(rhocla).lt.1.d-16) then
        erotpr(ind1)=0.d0
        erotsq(ind1)=0.d0
      endif
c     write(6,*)ind1,erotsq(ind1),esqodd,esqevn,rhoodd,rhoevn
   30 continue
c     write(2,'(a)')' '
   20 continue

c ... generate the symmetric pattens
      do iphi=90,180,increm
        do ichi=180-iphi,iphi,increm
          iphi0=180-ichi
          ichi0=180-iphi
          ind0=ithe*361*361+iphi0*361+ichi0
          ind1=ithe*361*361+iphi*361+ichi
          rhopro(ind1)=rhopro(ind0)
          erotpr(ind1)=erotpr(ind0)
          erotsq(ind1)=erotsq(ind0)
        enddo
      enddo
      do iphi=180,270,increm
        do ichi=iphi-180,360-iphi,increm
          iphi0=180+ichi
          ichi0=iphi-180
          ind0=ithe*361*361+iphi0*361+ichi0
          ind1=ithe*361*361+iphi*361+ichi
          rhopro(ind1)=rhopro(ind0)
          erotpr(ind1)=erotpr(ind0)
          erotsq(ind1)=erotsq(ind0)
        enddo
      enddo
      do iphi=180,360,increm
        do ichi=360-iphi,iphi,increm
          iphi0=360-ichi
          ichi0=360-iphi
          ind0=ithe*361*361+iphi0*361+ichi0
          ind1=ithe*361*361+iphi*361+ichi
          rhopro(ind1)=rhopro(ind0)
          erotpr(ind1)=erotpr(ind0)
          erotsq(ind1)=erotsq(ind0)
        enddo
      enddo
      do iphi=0,360
        do ichi=iphi,360
          iphi0=ichi
          ichi0=iphi
          ind0=ithe*361*361+iphi0*361+ichi0
          ind1=ithe*361*361+iphi*361+ichi
          rhopro(ind1)=rhopro(ind0)
          erotpr(ind1)=erotpr(ind0)
          erotsq(ind1)=erotsq(ind0)
        enddo
      enddo

c ... write the results in file 2 for iodevn=0 or 1, for which the symmetry
c ... is employed
      do iphi=0,360
        do ichi=0,360
          ind=ithe*361*361+iphi*361+ichi
          write(2,'(3(I5),3(1x,E15.8))')ithe,iphi,ichi,rhopro(ind),
     +                                erotpr(ind),erotsq(ind)
c         write(3,'(5x,''+'',1x,E15.8,'','')')dabs(rhopro(ind))
c         write(4,'(5x,''+'',1x,E15.8,'','')')erotpr(ind)
c         write(3,'(E15.8)')dabs(rhopro(ind))
          write(3,'(E15.8)')rhopro(ind)
          write(4,'(E15.8)')erotpr(ind)
          write(7,'(E15.8)')erotsq(ind)
        enddo
      enddo

      close(7,status='keep')
      close(4,status='keep')
      close(3,status='keep')
      close(2,status='keep')

   60 continue

c     write(6,*)coef1,coef2,eigvec(numcef),numcef,ivec

      end
c------------------------------------------------------------------
      integer function kdel(i,j)
      implicit double precision(a-h,o-z)

c ... shift-up for the situation of i=j=0
c ... because of the shifting, the delta function
c ... is ILL-DEFINED for the case of i=j=-1000
      ii=i+1000
      jj=j+1000
      kdel=((ii+jj)-iabs(ii-jj))/((ii+jj)+iabs(ii-jj))

      return
      end
c------------------------------------------------------------------

      double precision function cplus(j,k)
      implicit double precision(a-h,o-z)

      parameter(one=1.0d+00,zero=0.0d+00)

c ... in case k runs out of the range
      if(k.ge.j.or.k.lt.(-j)) then
        cplus=zero
        return
      endif

      dj=dfloat(j)
      dk=dfloat(k)

      cplus=sqrt(dj*(dj+one)-dk*(dk+one))

      return
      end
c------------------------------------------------------------------

      double precision function cminus(j,k)
      implicit double precision(a-h,o-z)

      parameter(one=1.0d+00,zero=0.0d+00)

c ... in case k runs out of the range
      if(k.le.(-j).or.k.gt.j)then
        cminus=zero
        return
      endif

      dj=dfloat(j)
      dk=dfloat(k)

      cminus=sqrt(dj*(dj+one)-dk*(dk-one))

      return
      end

c------------------------------------------------------------------
      double precision function rotmat(j,k,kp,A,B,C)
      implicit double precision(a-h,o-z)

      rotmat=0.d0
      if(iabs(k-kp).ne.0.and.(iabs(k-kp).ne.2)) then
        return
      elseif(k.eq.kp) then
        rotmat=0.5d0*(A+C)*dfloat(j*(j+1))+(B-0.5d0*(A+C))*dfloat(k*k)
        return
      elseif(k.eq.(kp+2))then
        rotmat=0.25d0*(A-C)*cplus(j,kp)*cplus(j,kp+1)
        return
      elseif(k.eq.(kp-2))then
        rotmat=0.25d0*(A-C)*cminus(j,kp)*cminus(j,kp-1)
        return
      else
        stop 'wrong with rotmat'
      endif


      return
      end
c------------------------------------------------------------------
      double precision function rotma2(j,k,kp,A,B,C)
      implicit double precision(a-h,o-z)

      rotma2=0.d0
      if(iabs(k-kp).ne.0.and.(iabs(k-kp).ne.2)) then
        return
      elseif(k.eq.kp) then
        rotma2=0.5d0*(B+C)*dfloat(j*(j+1)-k*k)+A*dfloat(k*k)
        return
      elseif(k.eq.(kp+2))then
        rotma2=0.25d0*(B-C)*cplus(j,kp)*cplus(j,kp+1)
        return
      elseif(k.eq.(kp-2))then
        rotma2=0.25d0*(B-C)*cminus(j,kp)*cminus(j,kp-1)
        return
      else
        stop 'wrong with rotma2'
      endif


      return
      end

c------------------------------------------------------------------
      SUBROUTINE TQL(MD,N,Z,D,E)
C       Z(-1) A  Z  =D                                    
C       A = Z
C       EIGENVALUE         D(I)
C       EIGENFUNCTION      Z(J,I),J=1,N
      IMPLICIT REAL*8(A-H,O-Z)
      DIMENSION   D(MD),E(MD),Z(MD,MD)
      EPS=1D-12
      NITER=50
      CALL TRED2(MD,N,Z,D,E)
      DO 10 I=2,N
  10  E(I-1)=E(I)
      F=0.0D0
      B=0.0D0
      E(N)=0.0D0
      DO 20 L=1,N
      J=0
      H=EPS*(DABS(D(L))+DABS(E(L)))
      LP1=L+1
      IF (B-H) 30,40,40
  30  B=H
  40  DO 50 M=L,N
      IF (DABS(E(M))-B) 60,60,50
  50  CONTINUE
  60  IF (M-L) 70,80,70
  70  IF (J-NITER) 90,100,90
  90  J=J+1
      P=(D(LP1)-D(L))/(2*E(L))
      R=DSQRT(P*P+1)
      IF (P) 110,111,111
  110 H=D(L)-E(L)/(P-R)
      GOTO 130
  111 H=D(L)-E(L)/(P+R)
  130 DO 140 I=L,N
  140 D(I)=D(I)-H
      F=F+H
      P=D(M)
      C=1.0D0
      S=0.0D0
      MM1=M-1
      IF (MM1-L) 270,280,280
  280 DO 120 LMIP=L,MM1
      I=L+MM1-LMIP
      IP1=I+1
      G=C*E(I)
      H=C*P
      IF (DABS(P)-DABS(E(I))) 160,170,170
  170 C=E(I)/P
      R=DSQRT(C*C+1.0D0)
      E(IP1)=S*P*R
      S=C/R
      C=1.0D0/R
      GOTO 180
  160 C=P/E(I)
      R=DSQRT(C*C+1)
      E(IP1)=S*E(I)*R
      S=1/R
      C=C/R
  180 P=C*D(I)-S*G
      D(IP1)=H+S*(C*G+S*D(I))
      DO 190 K=1,N
      H=Z(K,IP1)
      Z(K,IP1)=S*Z(K,I)+C*H
  190 Z(K,I)=C*Z(K,I)-S*H
  120 CONTINUE
  270 E(L)=S*P
      D(L)=C*P
      IF (DABS(E(L))-B) 80,80,70
  80  D(L)=D(L)+F
  20  CONTINUE
      DO 112 I=1,N
      IP1=I+1
      K=I
      P=D(I)
      IF (N-I) 230,230,300
  300 DO 210 J=IP1,N
      IF (D(J)-P) 220,210,210
  220 K=J
      P=D(J)
  210 CONTINUE
  230 IF (K-I) 240,112,240
  240 D(K)=D(I)
      D(I)=P
      DO 260 J=1,N
      P=Z(J,I)
      Z(J,I)=Z(J,K)
  260 Z(J,K)=P
  112 CONTINUE
      RETURN
  100 STOP '  FAIL'
      END
c------------------------------------------------------------------
      SUBROUTINE TRED2(MD,N,Z,D,E)
      IMPLICIT REAL*8(A-H,O-Z)
      DIMENSION  D(MD),E(MD),Z(MD,MD)
      BETA=1D-20
      DO 20 NMIP2=2,N
      I=N+2-NMIP2
      IM1=I-1
      IM2=I-2
      L=IM2
      F=Z(I,IM1)
      G=0.0D0
      IF (L) 30,30,40
  40  DO 50 K=1,L
  50  G=G+Z(I,K)*Z(I,K)
  30  H=G+F*F
      IF (G-BETA) 60,60,70
  60  E(I)=F
      H=0.0D0
      GOTO 180
  70  L=L+1
      IF (F) 80,90,90
  90  E(I)=-DSQRT(H)
      G=E(I)
      GOTO 100
  80  E(I)=DSQRT(H)
      G=E(I)
 100  H=H-F*G
      Z(I,IM1)=F-G
      F=0.0D0
      DO 110 J=1,L
      Z(J,I)=Z(I,J)/H
      G=0.0D0
      DO 201 K=1,J
  201 G=G+Z(J,K)*Z(I,K)
      JP1=J+1
      IF (JP1-L) 130,130,140
  130 DO 120 K=JP1,L
  120 G=G+Z(K,J)*Z(I,K)
  140 E(J)=G/H
      F=F+G*Z(J,I)
  110 CONTINUE
      HH=F/(H+H)
      DO 160    J=1,L
      F=Z(I,J)
      E(J)=E(J)-HH*F
      G=E(J)
      DO 170 K=1,J
  170 Z(J,K)=Z(J,K)-F*E(K)-G*Z(I,K)
  160 CONTINUE
  180 D(I)=H
  20  CONTINUE
      D(1)=0.0D0
      E(1)=0.0D0
      DO 190 I=1,N
      L=I-1
      IF (D(I)) 202,210,202
  202 IF (L) 210,210,220
  220 DO 230 J=1,L
      G=0.0D0
      DO 240 K=1,L
  240 G=G+Z(I,K)*Z(K,J)
      DO 250 K=1,L
  250 Z(K,J)=Z(K,J)-G*Z(K,I)
  230 CONTINUE
  210 D(I)=Z(I,I)
      Z(I,I)=1.0D0
      IF (L) 260,260,270
  270 DO 280 J=1,L
      Z(I,J)=0.0D0
  280 Z(J,I)=0.0D0
  260 CONTINUE
  190 CONTINUE
      return
      END
c------------------------------------------------------------------
      double precision function wigd(j,m,k,theta,maxfac,fact)
      implicit real*16(a-h,o-z)
      real*16 fact(0:maxfac)
      double precision theta
      parameter(eps=1.q-16)
c ... this function calculates the wigner d-matrix element.
c ... It takes Eq. 3.57 of Zare, 1988.

      pre1=sqrt(fact(j+k))*sqrt(fact(j-k))*sqrt(fact(j+m))*
     +     sqrt(fact(j-m))

c ... judge the upper bound of nu, the summing index
      nulow=max(0,k-m)
      nuup=min(j+k,j-m)
      thehlf=0.5q+00*theta
      wigd_temp=0.0q+00
c     wigd=0.0d+00

c ... summation over nu
      do nu=nulow,nuup
        denorm=fact(j-m-nu)*fact(j+k-nu)*fact(nu+m-k)*fact(nu)
     +          *(-1)**(nu)
        pre2=pre1/denorm
        cosfac=cos(thehlf)
        sinfac=-sin(thehlf)
        cosfac=cosfac**(2*j+k-m-2*nu)
        sinfac=sinfac**(m-k+2*nu)
        wigd_temp=wigd_temp+pre2*cosfac*sinfac
      enddo

      wigd=dble(wigd_temp)

      return
      end
c-----------------------------------------------------------------
      subroutine calfac(fact,maxfac)
      implicit double precision(a-h,o-z)
      real*16 fact(0:maxfac)

      fact(0)=1.0d+00

      do i=1,maxfac
        fact(i)=fact(i-1)*dfloat(i)
      enddo
      return
      end
c     Subroutine bubble_sort
c       this routine sorts the given data
c
      subroutine bubble_sort(data,count)
c     
c     argument:  count is a positive integer
      integer count
c     argument:  data is an array of size count
      double precision data(count)
c
c     local variables:
      integer i
c       how many times we have passed through the array
      integer pass
c       flag variable: 1 if sorted; 0 if not sorted  
      integer sorted
c       temporary variable used for swapping       
      double precision temp

      pass = 1
 1    continue
      sorted = 1
      do 2 i = 1,count-pass
        if(data(i) .gt. data(i+1)) then
          temp = data(i)
          data(i) = data(i+1)
          data(i+1) = temp
          sorted = 0
        endif
 2    continue
      pass = pass +1
      if(sorted .eq. 0) goto 1
      return
      end
c---------------------------------------------------------------------
      integer function lastch(line,len)
      implicit double precision(a-h,o-z)
      character*(*) line

      do i=len,1,-1
         if(line(i:i).ne.' ') then
           lastch=i
           return
         endif
      enddo
      return
      end
