module cmt3d_sub3

  use cmt3d_constants
  use cmt3d_variables

  implicit none

  contains

  !==================================================================

  subroutine  write_new_cmtsolution(cmt_file,new_cmt_file,new_par_all)

    character(len=*),intent(in) :: cmt_file,new_cmt_file
    real*8,intent(inout) :: new_par_all(NPARMAX)

    integer, parameter :: NSIG_DIGIT = 6
    character(len=150) :: pde_time,event_name,out_cmt
    real*8 :: exponent
    integer :: i, nn, exp_largest, iflag
    real*8 :: epsilon, s1, d1, r1, s2, d2, r2, mw, m0, m00

    open(21,file = cmt_file, status = 'old')
    read(21,'(a)') pde_time
    read(21,'(a)') event_name
    close(21)

!    output only NSIG_DIGITS of the moment tensor elements
    exp_largest = floor(log10(maxval(abs(new_par_all(1:6)))))
    nn = exp_largest - NSIG_DIGIT
    exponent = 1.0d1 ** nn
    do i = 1, 6
       new_par_all(i) = floor(new_par_all(i)/exponent)*exponent
    enddo

    open(22,file = new_cmt_file, status = 'unknown')
    write(22,'(a)') trim(pde_time)//' - INV'
    write(22,'(a)') trim(event_name)
    write(22,'(a,f12.4)') 'time shift:',new_par_all(10)
    write(22,'(a,f9.4)') 'half duration:',new_par_all(11)
    write(22,'(a,f14.4)') 'latitude:',new_par_all(9)
    write(22,'(a,f13.4)') 'longitude:',new_par_all(8)
    write(22,'(a,f17.4)') 'depth:',new_par_all(7)
    write(22,'(a,g19.6)') 'Mrr:',sngl(new_par_all(1))
    write(22,'(a,g19.6)') 'Mtt:',sngl(new_par_all(2))
    write(22,'(a,g19.6)') 'Mpp:',sngl(new_par_all(3))
    write(22,'(a,g19.6)') 'Mrt:',sngl(new_par_all(4))
    write(22,'(a,g19.6)') 'Mrp:',sngl(new_par_all(5))
    write(22,'(a,g19.6)') 'Mtp:',sngl(new_par_all(6))
    close(22)

!!$    iflag = 1
!!$
!!$    ! initial cmt
!!$    call mij(cmt_par(1:6),epsilon,s1,d1,r1,s2,d2,r2,m0,m00,iflag)
!!$    write(IOINV,*) ' '
!!$    write(IOINV,*) 'The initial solution :'
!!$    write(IOINV,*) 'Fault plane 1 : strike = ', sngl(s1), ', dip = ', &
!!$         sngl(d1), ', rake = ', sngl(r1)
!!$    write(IOINV,*) 'Fault plane 2 : strike = ', sngl(s2), ', dip = ', &
!!$         sngl(d2), ', rake = ', sngl(r2)
!!$    write(IOINV,*) 'Epsilon (-M3/M1)  = ', sngl(epsilon)
!!$    write(IOINV,*) 'Full Moment = ', sngl(m00), ' Devitoric Moment =', sngl(m0)
!!$    mw = log10(m00)/1.5-10.73
!!$    write(IOINV,*) 'Mw = ', sngl(mw)
!!$    write(IOINV,*) ' ------- '
!!$
!!$
!!$    call mij(new_par_all(1:6),epsilon,s1,d1,r1,s2,d2,r2,m0,m00,iflag)
!!$    write(IOINV,*) ' '
!!$    write(IOINV,*) 'The final solution :'
!!$    write(IOINV,*) 'Fault plane 1 : strike = ', sngl(s1), ', dip = ', &
!!$         sngl(d1), ', rake = ', sngl(r1)
!!$    write(IOINV,*) 'Fault plane 2 : strike = ', sngl(s2), ', dip = ', &
!!$         sngl(d2), ', rake = ', sngl(r2)
!!$    write(IOINV,*) 'Epsilon (-M3/M1)  = ', sngl(epsilon)
!!$    write(IOINV,*) 'Full Moment = ', sngl(m00), ' Devitoric Moment =', sngl(m0)
!!$    mw = log10(m00)/1.5-10.73
!!$    write(IOINV,*) 'Mw = ', sngl(mw)

  end subroutine write_new_cmtsolution


  !****************************************************************

  subroutine gaussian_elimination(A,n,b,x,singular)

    ! tired of finding a subroutine on the web, I decided
    ! to write my own version of Gaussian elimination
    ! with partial pivoting.
    ! solving A * x = b where A : n*n  b : n*1
    ! notice for efficiency in fortran, A (nrow,ncol) 

    implicit none

    integer,intent(in) :: n
    real*8,intent(inout) :: A(:,:),b(:)
    real*8,intent(out) :: x(:)
    logical,intent(out) :: singular

    integer :: i,j,k,pivot_row
    real*8 :: pivot,temp(n),temp1,l(n)
    real*8 ,parameter :: EPS = 1.0e-12


    ! perform gaussian ellimination

    do k = 1, n-1

       pivot_row = maxval(maxloc(abs(A(k:n,k)))) + k - 1
       if (abs(A(pivot_row,k)) < EPS) then
          singular = .true.
          return
       else
          singular = .false.
       endif

       if (pivot_row /= k) then
          temp(k:n) = A(pivot_row,k:n)
          A(pivot_row,k:n) = A(k,k:n)
          A(k,k:n) = temp(k:n)
          temp1 = b(pivot_row)
          b(pivot_row) = b(k)
          b(k) = temp1
       endif

       pivot = A(k,k)
       l(k+1:n) = A(k+1:n,k)/pivot
       do j = k+1, n
          A(j,k:n) = A(j,k:n) - l(j) * A(k,k:n)
          b(j) = b(j) - l(j) * b(k)
       enddo

    enddo

    ! solve Ax=b by backward substitution

    if (abs(A(n,n)) < EPS) then
       singular = .true.
       return
    endif

    x(n) = b(n) / A(n,n)
    do i = n-1,1,-1

       x(i) = (b(i) - sum(A(i,i+1:n) * x(i+1:n)))/A(i,i)

    enddo

    singular = .false.


  end subroutine gaussian_elimination

!==========================================================================

  subroutine xcorr_calc(d,s,npts,i1,i2,ishift,cc_max)

  ! borrowed from Alessia Maggi's flexwin
  ! inputs:
  ! s(npts) = synthetic
  ! d(npts) = data (or observed)
  ! i1, i2 = start and stop indexes of window within s and d 
  
  double precision, dimension(*), intent(in) :: s,d
  integer, intent(in) :: npts, i1, i2

  ! outputs:
  ! ishift = index lag (d-s) for max cross correlation
  ! cc_max = maximum of cross correlation (normalised by sqrt(synthetic*data))
  integer, intent(out) :: ishift
  double precision, intent(out) :: cc_max

  ! local variables
  integer :: nlen
  integer :: i_left, i_right, i, j, id_left, id_right
  double precision :: cc, norm

  ! initialise shift and cross correlation to zero
  ishift = 0
  cc_max = 0.0d0

  if (i1.lt.1 .or. i1.gt.i2 .or. i2.gt.npts) then
    write(*,*) 'Error with window limits: i1, i2, npts ', i1, i2, npts
    return
  endif

  ! length of window (number of points, including ends)
  nlen = i2 - i1 + 1

  ! left and right limits of index (time) shift search
  ! NOTE: This looks OUTSIDE the time window of interest to compute TSHIFT and CC.
  !       THIS IS A VERY IMPORTANT DECISION!
  i_left = -1*int(nlen/2.0)
  i_right = int(nlen/2.0)

  ! i -> shift (to be applied to DATA (d) in cc search) 
  do i = i_left, i_right
    cc = 0.
    id_left = max(1,i1+i)     ! left-most point on the data that will be treated
    id_right = min(npts,i2+i) ! right-most point on the data that will be treated
    norm = sqrt(sum(s(i1:i2)*s(i1:i2)) * sum(d(id_left:id_right)*(d(id_left:id_right))))
    do j = i1, i2 
      if((j+i).ge.1 .and. (j+i).le.npts) cc = cc + s(j)*d(j+i)
    enddo
    cc = cc/norm
    if (cc .gt. cc_max) then
      cc_max = cc
      ishift = i
    endif
  enddo

end subroutine xcorr_calc

!------------------------------------------------------------------------

end module cmt3d_sub3
