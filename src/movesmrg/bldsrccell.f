
        SUBROUTINE BLDSRCCELL( NSRC, NMAT, NU, IU, CU )

C***********************************************************************
C  subroutine BLDSRCCELL body starts at line
C
C  DESCRIPTION:
C      This subroutine uses the ungridding matrix to build a list of grid
C      cells and associated fractions for each source.
C
C  PRECONDITIONS REQUIRED:  
C
C  SUBROUTINES AND FUNCTIONS CALLED:
C
C  REVISION  HISTORY:
C       Created 4/10 by C. Seppanen
C
C***********************************************************************
C
C Project Title: Sparse Matrix Operator Kernel Emissions (SMOKE) Modeling
C                System
C File: @(#)$Id$
C
C COPYRIGHT (C) 2004, Environmental Modeling for Policy Development
C All Rights Reserved
C 
C Carolina Environmental Program
C University of North Carolina at Chapel Hill
C 137 E. Franklin St., CB# 6116
C Chapel Hill, NC 27599-6116
C 
C smoke@unc.edu
C
C Pathname: $Source$
C Last updated: $Date$ 
C
C****************************************************************************

C.........  MODULES for public variables
C.........  This module contains data structures and flags specific to Movesmrg
        USE MODMVSMRG, ONLY: NSRCCELLS, SRCCELLS, SRCCELLFRACS

        IMPLICIT NONE

C.........  INCLUDES:

C.........  SUBROUTINE ARGUMENTS
        INTEGER, INTENT(IN) :: NSRC        ! number of sources
        INTEGER, INTENT(IN) :: NMAT        ! dimension for matrixes
        INTEGER, INTENT(IN) :: NU( NSRC )  ! number of cells per source
        INTEGER, INTENT(IN) :: IU( NMAT )  ! list of cells per source
        REAL,    INTENT(IN) :: CU( NMAT )  ! list of grid cell fractions per source

C.........  LOCAL VARIABLES and their descriptions:

C.........  Other local variables
        INTEGER   INDX, NG, S        ! indexes and counters
        INTEGER   MXNSRCCELLS        ! max. no. cells per source
        INTEGER   IOS                ! error status

        CHARACTER(16) :: PROGNAME = 'BLDSRCCELL' ! program name

C***********************************************************************
C   begin body of subroutine BLDSRCCELL

C.........  Determine maximum number of cells per source
        ALLOCATE( NSRCCELLS( NSRC ), STAT=IOS )
        CALL CHECKMEM( IOS, 'NSRCCELLS', PROGNAME )

        MXNSRCCELLS = 0
        DO S = 1, NSRC
        
            NSRCCELLS( S ) = NU( S )
            IF( NU( S ) > MXNSRCCELLS ) MXNSRCCELLS = NU( S )
        
        END DO

C.........  Store list of cells and fractions for each source        
        ALLOCATE( SRCCELLS( NSRC, MXNSRCCELLS ), STAT=IOS )
        CALL CHECKMEM( IOS, 'SRCCELLS', PROGNAME )
        ALLOCATE( SRCCELLFRACS( NSRC, MXNSRCCELLS ), STAT=IOS )
        CALL CHECKMEM( IOS, 'SRCCELLFRACS', PROGNAME )

        INDX = 0
        DO S = 1, NSRC
        
            DO NG = 1, NSRCCELLS( S )

                INDX = INDX + 1
                SRCCELLS    ( S,NG ) = IU( INDX )
                SRCCELLFRACS( S,NG ) = CU( INDX )
            
            END DO
        
        END DO

        END SUBROUTINE BLDSRCCELL
