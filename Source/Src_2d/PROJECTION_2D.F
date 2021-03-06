
#undef  BL_LANG_CC
#ifndef BL_LANG_FORT
#define BL_LANG_FORT
#endif

#include <AMReX_REAL.H>
#include <AMReX_CONSTANTS.H>
#include <AMReX_BC_TYPES.H>
#include <PROJECTION_F.H>
#include <AMReX_ArrayLim.H>

#define SDIM 2

#if defined(BL_USE_FLOAT) || defined(BL_T3E) || defined(BL_CRAY)
#define SMALL 1.0e-10
#else
#define SMALL 1.0d-10
#endif

       subroutine FORT_ACCEL_TO_VEL( lo, hi, 
     &     uold,DIMS(uold),
     &     dt,
     &     unew,DIMS(unew) )
c
c     This function converts unew into a velocity via
c     Unew = Uold + alpha*Unew
c
       implicit none
       integer    lo(SDIM), hi(SDIM)
       REAL_T     dt
       integer    DIMDEC(uold),DIMDEC(unew)
       REAL_T     uold(DIMV(uold),SDIM)
       REAL_T     unew(DIMV(unew),SDIM)

       integer i, j, n

       do n = 1, SDIM
          do j = lo(2)-1, hi(2)+1
             do i = lo(1)-1, hi(1)+1
                unew(i,j,n) = uold(i,j,n) + dt*unew(i,j,n)
             end do
          end do
       end do

       end

      subroutine FORT_VEL_TO_ACCEL( lo, hi, 
     &     unew,DIMS(unew),
     &     uold,DIMS(uold),
     &     dt )
c     
c     This function converts unew into an acceleration
c
      implicit none
      integer    lo(SDIM), hi(SDIM)
      REAL_T     dt
      integer    DIMDEC(unew),DIMDEC(uold)
      REAL_T     uold(DIMV(uold),SDIM)
      REAL_T     unew(DIMV(unew),SDIM)
     
      integer i, j, n
      REAL_T dt_inv
   
      dt_inv = one/dt

      do n = 1, SDIM
         do j = lo(2)-1, hi(2)+1
            do i = lo(1)-1, hi(1)+1
               unew(i,j,n) = (unew(i,j,n)-uold(i,j,n))*dt_inv
            end do
         end do
      end do

      end

      subroutine FORT_PROJ_UPDATE(
     &     boxlo, boxhi, nvar, ngrow,
     &     un, DIMS(un),
     &     alpha,
     &     uo, DIMS(uo) )
c     
c     This function updates un via un = un + alpha*uo
c     The loop bounds are determined in the C++
c
      implicit none
      integer    boxlo(SDIM), boxhi(SDIM), nvar, ngrow
      REAL_T     alpha
      integer    DIMDEC(un),DIMDEC(uo)
      REAL_T     un(DIMV(un),nvar)
      REAL_T     uo(DIMV(uo),nvar)

      integer i, j, n

      do n = 1, nvar
         do j = boxlo(2), boxhi(2)
            do i = boxlo(1), boxhi(1)
               un(i,j,n) = un(i,j,n) + alpha*uo(i,j,n)
            end do
         end do
      end do

      end

      subroutine FORT_RADMPYSCAL(a,DIMS(grid),domlo,domhi,ng,r,nr,bogus_value)
c 
c     multiply A by Radius r
c
c 
c     NOTE: THIS ROUTINE HAS BEEN MODIFIED SO THAT ALL VALUES
c           OUTSIDE THE DOMAIN ARE SET TO BOGUS VALUE
c
      implicit none
      integer    ng,nr
      integer    DIMDEC(grid)
      integer    domlo(2), domhi(2)
      REAL_T     a(ARG_L1(grid)-ng:ARG_H1(grid)+ng, 
     $             ARG_L2(grid)-ng:ARG_H2(grid)+ng)
      REAL_T     r(ARG_L1(grid)-nr:ARG_H1(grid)+nr)
      REAL_T     bogus_value

      integer i, j

      do j = ARG_L2(grid)-ng, ARG_H2(grid)+ng
         do i = ARG_L1(grid)-ng, min(ARG_H1(grid)+ng,domhi(1))
           a(i,j) = r(i)*a(i,j)
         end do
      end do

c     NOTE: We used to set these to bogus_value to be sure that we didn't use them.
c           But now in the divu routine in the F90 solvers we need to include these
c           values in the stencil because they might contain inflow values, for example, 
c           and the only test is on the BC for the pressure solve, which doesn't
c           differentiate between inflow, reflecting and symmetry.

      if (ARG_L1(grid)-ng .lt. domlo(1)) then
         do j = ARG_L2(grid)-ng, ARG_H2(grid)+ng
         do i = ARG_L1(grid)-ng, domlo(1)-1
           a(i,j) = 0.d0
         end do
         end do
      end if

      if (ARG_H1(grid)+ng .gt. domhi(1)) then
         do j = ARG_L2(grid)-ng, ARG_H2(grid)+ng
         do i = domhi(1)+1, ARG_H1(grid)+ng
           a(i,j) = 0.d0
         end do
         end do
      end if

      end

      subroutine FORT_RADMPYVEL(a,DIMS(grid),domlo,domhi,ng,r,nr,ndim)
c 
c     multiply A by Radius r
c
c 
c     NOTE: THIS ROUTINE HAS BEEN MODIFIED SO THAT ALL VALUES
c           OUTSIDE THE DOMAIN ARE SET TO BOGUS VALUE
c
      implicit none
      integer    ng,nr,ndim
      integer    DIMDEC(grid)
      integer    domlo(2), domhi(2)
      REAL_T     a(ARG_L1(grid)-ng:ARG_H1(grid)+ng, 
     $             ARG_L2(grid)-ng:ARG_H2(grid)+ng)
      REAL_T     r(ARG_L1(grid)-nr:ARG_H1(grid)+nr)
      REAL_T     dr

      integer i, j

      do j = ARG_L2(grid)-ng, ARG_H2(grid)+ng
         do i = ARG_L1(grid)-ng, min(ARG_H1(grid)+ng,domhi(1))
           a(i,j) = r(i)*a(i,j)
         end do
      end do

c     NOTE: We used to set these to bogus_value to be sure that we didn't use them.
c           But now in the divu routine in the F90 solvers we need to include these
c           values in the stencil because they might contain inflow values, for example, 
c           and the only test is on the BC for the pressure solve, which doesn't
c           differentiate between inflow, reflecting and symmetry.

      if (ARG_L1(grid)-ng .lt. domlo(1)) then
         do j = ARG_L2(grid)-ng, ARG_H2(grid)+ng
         do i = ARG_L1(grid)-ng, domlo(1)-1
           a(i,j) = 0.d0
         end do
         end do
      end if

      dr = r(ARG_H1(grid)) - r(ARG_H1(grid)-1)
c     Here we only multiply a possibly inflow x-velocity from the hi-r side                
      if (ndim .eq. 0) then
         if (ARG_H1(grid)+ng .gt. domhi(1)) then
            do j = ARG_L2(grid)-ng, ARG_H2(grid)+ng
            do i = domhi(1)+1, ARG_H1(grid)+ng
              a(i,j) = (r(domhi(1)) + (i-domhi(1))*dr - 0.5*dr)*a(i,j)
            end do
            end do
         end if
      else
         if (ARG_H1(grid)+ng .gt. domhi(1)) then
            do j = ARG_L2(grid)-ng, ARG_H2(grid)+ng
            do i = domhi(1)+1, ARG_H1(grid)+ng
              a(i,j) = 0.d0
            end do
            end do
         end if
      end if

      end

      subroutine FORT_RADDIV(a,DIMS(grid),domlo,domhi,ng,r,nr,bogus_value)
c 
c     divide A by Radius r
c
c 
c     NOTE: THIS ROUTINE HAS BEEN MODIFIED SO THAT ALL VALUES
c           OUTSIDE THE DOMAIN ARE SET TO BOGUS VALUE
c
      implicit none
      integer    ng,nr
      integer    DIMDEC(grid)
      integer    domlo(2), domhi(2)
      REAL_T     a(ARG_L1(grid)-ng:ARG_H1(grid)+ng, 
     $             ARG_L2(grid)-ng:ARG_H2(grid)+ng)
      REAL_T     r(ARG_L1(grid)-nr:ARG_H1(grid)+nr)
      REAL_T     bogus_value

      integer i, j

      do j = ARG_L2(grid)-ng, ARG_H2(grid)+ng
         do i = ARG_L1(grid)-ng, ARG_H1(grid)+ng
           a(i,j) = a(i,j)/r(i)
         end do
      end do

      if (ARG_L1(grid)-ng .lt. domlo(1)) then
         do j = ARG_L2(grid)-ng, ARG_H2(grid)+ng
         do i = ARG_L1(grid)-ng, domlo(1)-1
           a(i,j) = bogus_value
         end do
         end do
      end if

      if (ARG_H1(grid)+ng .gt. domhi(1)) then
         do j = ARG_L2(grid)-ng, ARG_H2(grid)+ng
         do i = domhi(1)+1, ARG_H1(grid)+ng
           a(i,j) = bogus_value
         end do
         end do
      end if

      end

      subroutine FORT_ANELCOEFFMPY(a,DIMS(grid),domlo,domhi,ng,anel_coeff,nr,bogus_value,mult)
c 
c     multiply A by the anelastic coefficient
c
c 
c     NOTE: THIS ROUTINE HAS BEEN MODIFIED SO THAT ALL VALUES
c           OUTSIDE THE DOMAIN ARE SET TO BOGUS VALUE
c
      implicit none
      integer    ng,nr
      integer    DIMDEC(grid)
      integer    domlo(2), domhi(2)
      REAL_T     a(ARG_L1(grid)-ng:ARG_H1(grid)+ng, 
     $             ARG_L2(grid)-ng:ARG_H2(grid)+ng)
      REAL_T     anel_coeff(ARG_L2(grid)-nr:ARG_H2(grid)+nr)
      REAL_T     bogus_value
      integer    mult

      integer i, j

      if (mult .eq. 1) then
         do j = ARG_L2(grid)-ng, ARG_H2(grid)+ng
         do i = ARG_L1(grid)-ng, ARG_H1(grid)+ng
           a(i,j) = a(i,j) * anel_coeff(j)
         end do
         end do
      else if (mult .eq. 0) then
         do j = ARG_L2(grid)-ng, ARG_H2(grid)+ng
         do i = ARG_L1(grid)-ng, ARG_H1(grid)+ng
           a(i,j) = a(i,j) / anel_coeff(j)
         end do
         end do
      else 
         print *,'BOGUS MULT IN ANELCOEFFMULT ',mult
         stop
      end if

      if (ARG_L2(grid)-ng .lt. domlo(2)) then
         do i = ARG_L1(grid)-ng, ARG_H1(grid)+ng
         do j = ARG_L2(grid)-ng, domlo(2)-1
           a(i,j) = bogus_value
         end do
         end do
      end if

      if (ARG_H2(grid)+ng .gt. domhi(2)) then
         do i = ARG_L1(grid)-ng, ARG_H1(grid)+ng
         do j = domhi(2)+1, ARG_H2(grid)+ng
           a(i,j) = bogus_value
         end do
         end do
      end if

      end

      subroutine FORT_HGN2C(
     &     isrz,lrweighted, DIMS(nodedat), nodedat,
     &     DIMS(ccdat), lo, hi, ccdat)

c     ----------------------------------------------------------
c     HGN2C
c     averages node centered data to cell centers for use in 
c     holy grail projection

      implicit none
      integer isrz,lrweighted
      integer lo(SDIM), hi(SDIM)
      integer DIMDEC(ccdat)
      integer DIMDEC(nodedat)
      REAL_T  nodedat(DIMV(nodedat))
      REAL_T  ccdat(DIMV(ccdat))

      integer i,j

      if (ARG_H1(ccdat)   .lt. lo(1) .or. 
     &    ARG_L1(ccdat)   .gt. hi(1) .or. 
     &    ARG_H2(ccdat)   .lt. lo(2) .or. 
     &    ARG_L2(ccdat)   .gt. hi(2) .or. 
     &    ARG_H1(nodedat) .lt. lo(1)+1 .or. 
     &    ARG_L1(nodedat) .gt. hi(1) .or. 
     &    ARG_H2(nodedat) .lt. lo(2)+1 .or. 
     &    ARG_L2(nodedat) .gt. hi(2) ) then 
        call bl_abort("FORT_HG_CELL_TO_NODE: bad index limits")
      end if

      if(isrz.eq.1.and.lrweighted.ne.1)then
        call bl_abort('FORT_HGN2C: isrz=1 and lrweighted!=1 not implmented')
      end if

      do j=lo(2),hi(2)
        do i=lo(1),hi(1)
          ccdat(i,j) = fourth*(nodedat(i,j)+nodedat(i+1,j)+
     &                         nodedat(i,j+1)+nodedat(i+1,j+1))
        end do
      end do

      end

      subroutine FORT_HGC2N(
     &     nghost, DIMS(dat), dat, rcen,
     &     DIMS(rhs), rhs,
     &     domlo, domhi, dr, is_rz, imax) 
c
c     ----------------------------------------------------------
c     HGC2N
c     averages cell centered data to nodes for use in 
c     holy grail projection
c     
c     INPUTS / OUTPUTS:
c     nghost      => indicates buffer of rhs that does not need values
c     dat         => cell centered array to be averaged
c     DIMS(dat)   => index limits of dat
c     rcen        => r-coordinate cell centers if geoem is r-z; 
c     otherwise, should be 1
c     rhslo,rhshi => index extents of rhs
c     rhs         <= node centered array with results
c     ----------------------------------------------------------
c 
      implicit none
      integer nghost 
      integer domlo(SDIM), domhi(SDIM)
      integer DIMDEC(dat)
      integer DIMDEC(rhs)
      REAL_T  dr
      REAL_T  rcen(DIM1(dat))
      REAL_T  dat(DIMV(dat))
      REAL_T  rhs(DIMV(rhs))
      integer is_rz, imax

      integer i, j
      REAL_T  rhi, rlo

#if BL_PRVERSION == 9
      REAL_T  factor
#endif

      if (ARG_L1(rhs)+1 .lt. ARG_L1(dat) .or. 
     $     ARG_H1(rhs)-1 .gt. ARG_H1(dat) .or.
     &     ARG_L2(rhs)+1 .lt. ARG_L2(dat) .or. 
     $     ARG_H2(rhs)-1 .gt. ARG_H2(dat)) then
         call bl_abort("FORT_HG_CELL_TO_NODE: bad index limits")
      end if

      if (is_rz.ne.1) then
         do j=ARG_L2(rhs)+nghost,ARG_H2(rhs)-nghost
            do i=ARG_L1(rhs)+nghost,ARG_H1(rhs)-nghost
               rhs(i,j) = fourth*(dat(i-1,j-1)+dat(i-1,j)+
     &                            dat(i  ,j-1)+dat(i  ,j) )
            end do
         end do

      else

#if BL_PRVERSION == 9
         do j=ARG_L2(rhs)+nghost,ARG_H2(rhs)-nghost
            do i=ARG_L1(rhs)+nghost,ARG_H1(rhs)-nghost
               if (i .eq. imax) then
                  rhi = rcen(i-1)
               else 
                  rhi = rcen(i)
               end if
               if (i .eq. 0) then
                  rlo = rcen(i)
               else
                  rlo = rcen(i-1)
               end if

               rhs(i,j) = fourth*(rlo * (dat(i-1,j-1) + dat(i-1,j)) +
     &                            rhi * (dat(i  ,j-1) + dat(i  ,j)))
            end do
         end do
         factor = dr/24.0D0
         do j=ARG_L2(rhs)+nghost,ARG_H2(rhs)-nghost
            do i=ARG_L1(rhs)+nghost,ARG_H1(rhs)-nghost
               if (i .eq. imax) then
                  rhi = -one
               else 
                  rhi = one
               end if
               if (i .eq. 0) then
                  rlo = -one
               else
                  rlo = one
               end if
               rhs(i,j) = rhs(i,j) + factor *
     &              (rlo * (dat(i-1,j-1) + dat(i-1,j)) -
     &               rhi * (dat(i  ,j-1) + dat(i  ,j)))
            end do
         end do

#else
         do j=ARG_L2(rhs)+nghost,ARG_H2(rhs)-nghost
            do i=ARG_L1(rhs)+nghost,ARG_H1(rhs)-nghost
               if (i .eq. imax) then
                  rhi = rcen(i-1)
               else 
                  rhi = rcen(i)
               end if
               if (i .eq. 0) then
                  rlo = rcen(i)
               else 
                  rlo = rcen(i-1)
               end if
               rhs(i,j) = fourth*(rlo * (dat(i-1,j-1) + dat(i-1,j)) +
     &                            rhi * (dat(i  ,j-1) + dat(i  ,j)))
               if (i .eq. 0) rhs(i,j) = half * rhs(i,j)
            end do
         end do
#endif
      end if

      end
