
        PROGRAM SMKMERGE

C***********************************************************************
C  program SMKMERGE body starts at line 138
C
C  DESCRIPTION:
C      The purpose of this program is to merge the inventory or hourly
C      emissions files from the Temporal program with gridding matrices and 
C      with optionally any combination of speciation matrices and 3 control
C      matrices (different types).  The program can operate on from 1 to 4 
C      source categories (area, biogenic, mobile, or point sources), or any 
C      combination of these.  If a layer fractions file is input, then the 
C      output file is 3-d.  This program is not used for the MPS/MEPSE files 
C      for CMAQ.
C
C  PRECONDITIONS REQUIRED:  
C
C  SUBROUTINES AND FUNCTIONS CALLED:
C
C  REVISION  HISTORY:
C       Copied from csgldaymrg.F version 1.7 by M Houyoux 2/99
C
C***********************************************************************
C
C Project Title: Sparse Matrix Operator Kernel Emissions (SMOKE) Modeling
C                System
C File: @(#)$Id$
C
C COPYRIGHT (C) 1999, MCNC--North Carolina Supercomputing Center
C All Rights Reserved
C
C See file COPYRIGHT for conditions of use.
C
C Environmental Programs Group
C MCNC--North Carolina Supercomputing Center
C P.O. Box 12889
C Research Triangle Park, NC  27709-2889
C
C env_progs@mcnc.org
C
C Pathname: $Source$
C Last updated: $Date$ 
C
C****************************************************************************

C.........  MODULES for public variables
C.........  This module contains the major data structure and control flags
        USE MODMERGE

C.........  This module contains the control packet data and control matrices
        USE MODCNTRL

C.........  This module contains the lists of unique source characteristics
        USE MODLISTS

C.........  This module contains the arrays for state and county summaries
        USE MODSTCY

C...........   This module contains the gridding surrogates tables
        USE MODSURG

        IMPLICIT NONE

C...........   INCLUDES:
        
        INCLUDE 'EMCNST3.EXT'   !  emissions constant parameters
        INCLUDE 'PARMS3.EXT'    !  I/O API parameters
        INCLUDE 'IODECL3.EXT'   !  I/O API function declarations
        INCLUDE 'FDESC3.EXT'    !  I/O API file desc. data structures

C...........   EXTERNAL FUNCTIONS and their descriptions:
        
        CHARACTER*2     CRLF
        CHARACTER*10    HHMMSS
        INTEGER         INDEX1
        CHARACTER*14    MMDDYY
        INTEGER         WKDAY

        EXTERNAL    CRLF, HHMMSS, INDEX1, MMDDYY, WKDAY

C.........  LOCAL PARAMETERS and their descriptions:

        CHARACTER*50, PARAMETER :: SCCSW = '@(#)$Id$'

C...........   LOCAL VARIABLES and their descriptions:

C...........   Local temporary array for input and output variable names
        CHARACTER(LEN=IOVLEN3), ALLOCATABLE :: OUTNAMES( : )
        CHARACTER(LEN=IOVLEN3), ALLOCATABLE :: INNAMES ( : )

C...........   Logical names and unit numbers (not in MODMERGE)
        INTEGER         LDEV
     
C...........   Other local variables
    
        INTEGER          J, K, L1, L2, M, N, V, T ! counters and indices

        INTEGER       :: IDUM = 0      ! dummy integer value
        INTEGER          IDUM1, IDUM2
        INTEGER          IOS           ! tmp I/O status
        INTEGER          JDATE         ! Julian date (YYYYDDD)
        INTEGER          JTIME         ! time (HHMMSS)
        INTEGER       :: K1 = 0        ! tmp index for valid ar spc matrix
        INTEGER       :: K2 = 0        ! tmp index for valid mb spc matrix
        INTEGER       :: K3 = 0        ! tmp index for valid pt spc matrix
        INTEGER       :: K4 = 0        ! tmp index for valid ar reactvty matrix
        INTEGER       :: K5 = 0        ! tmp index for valid mb reactvty matrix
        INTEGER          KA, KB, KM, KP! tmp index to src-category species
        INTEGER          LDATE         ! Julian date from previous iteration
        INTEGER          MXGRP         ! max no. of variable groups
        INTEGER          MXVARPGP      ! max no. of variables per group
        INTEGER          NGRP          ! actual no. of pollutant groups
        INTEGER          NMAJOR        ! no. elevated sources (not used)
        INTEGER          NPING         ! no. plum-in-grid sources
        INTEGER          OCNT          ! tmp count output variable names
        INTEGER          PGID          ! previous iteration group ID no.
        INTEGER          NVPGP         ! tmp actual no. variables per group

        REAL          :: RDUM = 0      ! dummy real value
        REAL             RDUM1, RDUM2, RDUM3, RDUM4, RDUM5, RDUM6
        REAL             F1, F2, FB    ! tmp conversion factors

        CHARACTER*16     GRDNMBUF !  grid name
        CHARACTER*16     SRGFMT   ! gridding surrogates format
        CHARACTER*80     GDESCBUF !  grid description
        CHARACTER*300          MESG    ! message buffer
        CHARACTER(LEN=IOVLEN3) LBUF    ! previous species or pollutant name
        CHARACTER(LEN=IOVLEN3) PBUF    ! tmp pollutant or emission type name
        CHARACTER(LEN=IOVLEN3) SBUF    ! tmp species or pollutant name
        CHARACTER(LEN=PLSLEN3) VBUF    ! pol to species or pol description buffer

        CHARACTER*16  :: PROGNAME = 'SMKMERGE' ! program name

C***********************************************************************
C   begin body of program SMKMERGE
        
        LDEV = INIT3()

C.........  Write out copywrite, version, web address, header info, and prompt
C           to continue running the program.
        CALL INITEM( LDEV, SCCSW, PROGNAME )

C.........  Retrieve control environment variables and set logical control
C           flags. Use a local module to pass the control flags.
        CALL GETMRGEV
        
C.........  Open input files and retrieve episode information
        CALL OPENMRGIN

C.........  Do setup for biogenic state and county reporting
        IF( BFLAG .AND. LREPANY ) THEN

C.............  Read gridding surrogates header (to get srg format only)
            CALL RDSRGHDR( GDEV, SRGFMT, GRDNMBUF, GDESCBUF, RDUM1, 
     &                     RDUM2, RDUM3, RDUM4, RDUM5, RDUM6, 
     &                     IDUM1, IDUM2 )
    
C.............  Read gridding surrogates
            CALL RDSRG( GDEV, SRGFMT, XCENT, YCENT, XORIG, YORIG, 
     &                  XCELL, YCELL, NCOLS, NROWS )

        END IF

C.........  Create arrays of sorted unique pol-to-species
C.........  Create arrays of sorted unique pollutants
C.........  Create arrays of sorted unique species
        CALL MRGVNAMS

C.........  Determine units conversion factors
        CALL MRGUNITS

C.........  Read in any needed source characteristics
        CALL RDMRGINV

C.........  Do setup for state and county reporting
        IF( LREPANY ) THEN

C.............  Read the state and county names file and store for the 
C               states and counties in the grid
C.............  For biogenic included in merge, use list of codes from the 
C               surrogates file needed for state and county totals
            IF( BFLAG ) THEN
                CALL RDSTCY( CDEV, NSRGFIPS, SRGFIPS )

C.............  Otherwise, for anthropogenic source categories, use FIPS list
C               from the inventory for limiting state/county list
            ELSE
                CALL RDSTCY( CDEV, NINVIFIP, INVIFIP )

            END IF

        END IF

C.........  Allocate memory for fixed-size arrays by source category...
        CALL ALLOCMRG( MXGRP, MXVARPGP )

C.........  Read in plume-in-grid information, if needed
C.........  Reset flag for PinG if none in the input file
        IF( PFLAG .AND. PINGFLAG ) THEN

            CALL RDPELV( EDEV, NPSRC, NMAJOR, NPING )

            IF( NPING .EQ. 0 ) THEN
                MESG = 'WARNING: No sources are PinG sources in ' //
     &                 'input file, so none will be written'
                CALL M3MSG2( MESG )
                PINGFLAG = .FALSE.
            END IF
        END IF

C.........  Read reactivity matrices
        IF( ARFLAG ) CALL RDRMAT( ARNAME, ANSREAC, ARNMSPC, ACRIDX, 
     &                            ACRREPEM, ACRPRJFC, ACRMKTPN, ACRFAC )

        IF( MRFLAG ) CALL RDRMAT( MRNAME, MNSREAC, MRNMSPC, MCRIDX, 
     &                            MCRREPEM, MCRPRJFC, MCRMKTPN, MCRFAC )

        IF( PRFLAG ) CALL RDRMAT( PRNAME, PNSREAC, PRNMSPC, PCRIDX, 
     &                            PCRREPEM, PCRPRJFC, PCRMKTPN, PCRFAC )

C.........  Read gridding matrices (note, must do through subroutine because of
C           needing contiguous allocation for integer and reals)
        IF( AFLAG ) CALL RDGMAT( AGNAME, NGRID, ANGMAT, ANGMAT,
     &                           AGMATX( 1 ), AGMATX( NGRID + 1 ),
     &                           AGMATX( NGRID + ANGMAT + 1 ) )

        IF( MFLAG ) CALL RDGMAT( MGNAME, NGRID, MNGMAT, MNGMAT,
     &                           MGMATX( 1 ), MGMATX( NGRID + 1 ),
     &                           MGMATX( NGRID + MNGMAT + 1 ) )

        IF( PFLAG ) THEN

            PGMATX = 1.  ! initialize array b/c latter part not in file
            CALL RDGMAT( PGNAME, NGRID, NPSRC, 1,
     &                   PGMATX( 1 ), PGMATX( NGRID + 1 ), RDUM )
        END IF

C.........  Build indicies for pollutant/species groups
        CALL BLDMRGIDX( MXGRP, MXVARPGP, NGRP )

C.........  Open NetCDF output files, open ASCII report files, and write headers
        CALL OPENMRGOUT( NGRP )

C.........  In case reactivity does not exist, initialize temporary arrays
C           for reactivity information anyway.  These are used even without
C           reactivity matrix inputs so that the code does not need even
C           more conditionals in the matrix multiplication step.
        IF( AFLAG ) ARINFO = 0.  ! array
        IF( MFLAG ) MRINFO = 0.  ! array
        IF( PFLAG ) PRINFO = 0.  ! array

C.........  Intialize state/county summed emissions to zero
        CALL INITSTCY

C.........  Allocate memory for temporary list of species and pollutant names
        ALLOCATE( OUTNAMES( MXVARPGP ), STAT=IOS )
        CALL CHECKMEM( IOS, 'OUTNAMES', PROGNAME )
        ALLOCATE( INNAMES( MXVARPGP ), STAT=IOS )
        CALL CHECKMEM( IOS, 'INNAMES', PROGNAME )

C.........  Loop through processing groups (if speciation, this will be specia-
C           tion groups, but if no speciation, this will be pollutant groups,  
C           for purposes of memory usage if many pollutants and/or species)
        PGID = IMISS3
        DO N = 1, NGRP

C.............  Set the number of variables per group
            NVPGP = VGRPCNT( N )

C.............  If pollutants in current group are different from those
C               in the previous group, read pollutant-specific control matrices
C.............  For reactivity matrices, read inventory emissions that will
C               be needed for getting ratios of inventory to hourly for applying
C               reactivity-based projection to hourly emissions
C.............  Note that only the pollutants in this group that are actually
C               in the control matrices are stored, and the index that says
C               which are valid is *U_EXIST and *A_EXIST
            IF( IDVGP( N ) .NE. PGID ) THEN

                IF( AUFLAG )
     &              CALL RD3MASK( AUNAME, 0, 0, NASRC, NVPGP, 
     &                      GVNAMES( 1,N ), AU_EXIST( 1,N ), ACUMATX )

                IF( MUFLAG )
     &              CALL RD3MASK( MUNAME, 0, 0, NMSRC, NVPGP, 
     &                      GVNAMES( 1,N ), MU_EXIST( 1,N ), MCUMATX )

                IF( PUFLAG )
     &              CALL RD3MASK( PUNAME, 0, 0, NPSRC, NVPGP, 
     &                      GVNAMES( 1,N ), PU_EXIST( 1,N ), PCUMATX )

                IF( AAFLAG )
     &              CALL RD3MASK( AANAME, 0, 0, NASRC, NVPGP, 
     &                      GVNAMES( 1,N ), AA_EXIST( 1,N ), ACAMATX )

                IF( MAFLAG )
     &              CALL RD3MASK( MANAME, 0, 0, NMSRC, NVPGP, 
     &                      GVNAMES( 1,N ), MU_EXIST( 1,N ), MCAMATX )

                IF( PAFLAG )
     &              CALL RD3MASK( PANAME, 0, 0, NPSRC, NVPGP, 
     &                      GVNAMES( 1,N ), PA_EXIST( 1,N ), PCAMATX )

                IF( ARFLAG )
     &              CALL RD3MASK( AENAME, 0, 0, NASRC, NVPGP,
     &                      GVNAMES( 1,N ), A_EXIST( 1,N ), AEISRC   )

                IF( MRFLAG ) 
     &              CALL RD3MASK( MENAME, 0, 0, NMSRC, NVPGP, 
     &                      GVNAMES( 1,N ), M_EXIST( 1,N ), MEISRC   )

                IF( PRFLAG )
     &              CALL RD3MASK( PENAME, 0, 0, NPSRC, NVPGP, 
     &                      GVNAMES( 1,N ), P_EXIST( 1,N ), PEISRC   )

            END IF

C.............  Loop through variables in current group...
            OCNT = 0
            LBUF = ' '
            INNAMES  = ' '  ! array
            OUTNAMES = ' '  ! array
            DO V = 1, NVPGP  ! No. variables per group 

                K1 = 0
                K2 = 0
                K3 = 0

C.................  Extract name of variable in group
                VBUF = GVNAMES( V,N )

C.................  For speciation...
        	IF( SFLAG ) THEN

C.....................  Update list of output species names for message
                    SBUF = EMNAM( SPINDEX( V,N ) )
                    PBUF = EANAM( SIINDEX( V,N ) )
                    M = INDEX1( SBUF, OCNT, OUTNAMES )

                    IF( M .LE. 0 .AND. SBUF .NE. LBUF ) THEN
                        OCNT = OCNT + 1                            
                        OUTNAMES( OCNT ) = SBUF
                        LBUF = SBUF
                    END IF

C.....................  Set position for input of speciation matrix
                    IF( AFLAG ) K1 = AS_EXIST( V,N ) 
                    IF( MFLAG ) K2 = MS_EXIST( V,N ) 
                    IF( PFLAG ) K3 = PS_EXIST( V,N ) 

C.....................  Read speciation matrix for current variable and
C                       position
                    IF ( K1 .GT. 0 )
     &                    CALL RDSMAT( ASNAME, VBUF, ASMATX( 1,K1 ) )
                    IF ( K2 .GT. 0 )
     &                    CALL RDSMAT( MSNAME, VBUF, MSMATX( 1,K2 ) )
                    IF ( K3 .GT. 0 )
     &                    CALL RDSMAT( PSNAME, VBUF, PSMATX( 1,K3 ) )

C.................  For no speciation, prepare list of variables for output mesg
        	ELSE

C.....................  Update list of pollutants names for message
                    PBUF = EANAM( SIINDEX( V,N ) )
                    M = INDEX1( PBUF, OCNT, OUTNAMES )

                    IF( M .LE. 0 ) THEN
                        OCNT = OCNT + 1                            
                        OUTNAMES( OCNT ) = PBUF
                    END IF

        	END IF  ! end speciation or not

C.................  Set input variable names
                INNAMES ( V ) = PBUF

            END DO      ! End variables in group loop

C.............  Write out message about data currently being processed
            CALL POLMESG( OCNT, OUTNAMES )
 
C.............  Loop through output time steps
            JDATE = SDATE
            JTIME = STIME
            LDATE = 0
            DO T = 1, NSTEPS   ! at least once for time-independent

C................. For time-dependent processing, write out a few messages...
                IF( TFLAG ) THEN
                    
C.....................  Write out message for new day.  Note, For time-
C                       independent, LDATE and JDATE will both be zero.
                    IF( JDATE .NE. LDATE ) THEN

                        CALL WRDAYMSG( JDATE, MESG )

                    END IF

C.....................  For new hour...
C.....................  Write to screen because WRITE3 only writes to LDEV
                    WRITE( *, 93020 ) HHMMSS( JTIME )

                END IF

C.................  If area sources, read inventory emissions for this time 
C                   step for all area-source pollutants in current pol group
C.................  The *_EXIST are counters that point to the position in
C                   the source category emissions of the variables names 
C                   in INNAMES. Data are stored in *EMSRC in the global order.
                IF( AFLAG )
     &              CALL RD3MASK( ATNAME, JDATE, JTIME, NASRC, NVPGP,
     &                      INNAMES( 1 ), A_EXIST( 1,N ), AEMSRC   )

C.................  If mobile sources, read inventory emissions or activities
C                   for this time step for all mobile-source pollutants in 
C                   current pol group
                IF( MFLAG ) 
     &              CALL RD3MASK( MTNAME, JDATE, JTIME, NMSRC, NVPGP, 
     &                      INNAMES( 1 ), M_EXIST( 1,N ), MEMSRC   )

C.................  If point sources, read inventory emissions for this time 
C                   step for all point-source pollutants in current pol group
                IF( PFLAG )
     &              CALL RD3MASK( PTNAME, JDATE, JTIME, NPSRC, NVPGP, 
     &                      INNAMES( 1 ), P_EXIST( 1,N ), PEMSRC   )

C.................  If layer fractions, read them for this time step
                IF( LFLAG ) THEN

                    IF( .NOT. READ3( PLNAME, 'LFRAC', ALLAYS3, 
     &                               JDATE, JTIME, LFRAC      ) ) THEN

                        MESG = 'Could not read LFRAC from ' // PLNAME
                        CALL M3EXIT( PROGNAME, JDATE, JTIME, MESG, 2 )

                    END IF   ! if read3() failed

                END IF

C.................  Loop through variables in the current group
                LBUF = ' '
                DO V = 1, NVPGP

C.....................  Set species or pollutant/activity name for this 
C                       iteration
        	    IF( SFLAG ) THEN
                        SBUF = EMNAM( SPINDEX( V,N ) )
                        KA   = INDEX1( SBUF, ANMSPC, AEMNAM )
                        KB   = INDEX1( SBUF, BNMSPC, BEMNAM )
                        KM   = INDEX1( SBUF, MNMSPC, MEMNAM )
                        KP   = INDEX1( SBUF, PNMSPC, PEMNAM )
                    ELSE
                        SBUF = EANAM( SIINDEX( V,N ) )
                    END IF

C.....................  Set conversion factors
                    F1 = GRDFAC( SIINDEX( V,N ) )
                    F2 = TOTFAC( SIINDEX( V,N ) )

C.....................  If area reactivity matrix applies, pre-compute
C                       source array of reactivity emissions & mkt pentrtn
                    IF( ARFLAG ) THEN
                        K1 = A_EXIST ( V,N )
                        K2 = AR_EXIST( V,N )
                        IF( K2 .GT. 0 ) THEN
                            CALL APPLREAC( NASRC, ANSREAC, K1, K2, 
     &                             APRJFLAG, LMKTPON, AEISRC,AEMSRC, 
     &                             ACRIDX, ACRREPEM, ACRPRJFC, 
     &                             ACRMKTPN, ACRFAC, ARINFO )

                        ELSE
                            ARINFO = 0.  ! array
                        END IF
                    END IF

C.....................  Process for area sources...
                    IF( AFLAG ) THEN

                        K1 = A_EXIST ( V,N )
                        K2 = AU_EXIST( V,N )
                        K3 = AA_EXIST( V,N )
                        K4 = AS_EXIST( V,N )
                        K5 = NGRID + ANGMAT + 1

C.............................  Apply valid matrices & store
                        CALL MRGMULT( NASRC, NGRID, 1, ANGMAT, 
     &                         ANGMAT, K1, K2, K3, K4, KA, F1, F2, 
     &                         AEMSRC, ARINFO, ACUMATX, ACAMATX, ASMATX, 
     &                         AGMATX(1), AGMATX(NGRID+1), 
     &                         AGMATX(K5), AICNY, AEMGRD, TEMGRD,
     &                         AEBCNY, AEUCNY, AEACNY, AERCNY, 
     &                         AECCNY )
                    END IF
                            
C.....................  For biogenic sources, read gridded emissions,
C                       add to totals and store
                    IF( BFLAG ) THEN

                        K4 = BS_EXIST( V,N )

                        IF( K4 .GT. 0 ) THEN
                            CALL MRGBIO( SBUF, BTNAME, JDATE, JTIME, 
     &                                   NGRID, BIOGFAC, BEMGRD, 
     &                                   TEMGRD( 1,1 ) )
                    

C.............................  Update country, state, & county totals  
C.............................  Also convert the units from the gridded output
C                               units to the totals output units
                            IF( LREPANY ) THEN
                                FB = BIOTFAC / BIOGFAC
                                CALL GRD2CNTY( 0, KB, NGRID, NCOUNTY, 
     &                                         FB, BEMGRD, BEBCNY )

                            END IF
                        END IF

                    END IF
                            
C.....................  If mobile reactivity matrix applies, pre-compute
C                       source array of reacvty emissions and mkt pntrtn
                    IF( MRFLAG ) THEN
                        K1 = M_EXIST ( V,N )
                        K2 = MR_EXIST( V,N )
                        IF( K2 .GT. 0 ) THEN
                            CALL APPLREAC( NMSRC, MNSREAC, K1, K2, 
     &                             MPRJFLAG, LMKTPON, MEISRC,MEMSRC,
     &                             MCRIDX, MCRREPEM, MCRPRJFC, 
     &                             MCRMKTPN, MCRFAC, MRINFO )

                        ELSE
                            MRINFO = 0.  ! array
                        END IF

                    END IF

C.....................  Process for mobile sources...
                    IF( MFLAG ) THEN

                        K1 = M_EXIST ( V,N )
                        K2 = MU_EXIST( V,N )
                        K3 = MA_EXIST( V,N )
                        K4 = MS_EXIST( V,N )
                        K5 = NGRID + MNGMAT + 1
                           
C.........................  Apply valid matrices & store
                        CALL MRGMULT( NMSRC, NGRID, 1, MNGMAT,
     &                         MNGMAT, K1, K2, K3, K4, KM, F1, F2, 
     &                         MEMSRC, MRINFO, MCUMATX, MCAMATX, MSMATX, 
     &                         MGMATX(1), MGMATX(NGRID+1), 
     &                         MGMATX(K5), MICNY, MEMGRD, TEMGRD,
     &                         MEBCNY, MEUCNY, MEACNY, MERCNY, 
     &                         MECCNY )

                    END IF

C.....................  If reactivity matrix applies, pre-compute source
C                       array of reactivity emissions and market penetration
                    IF( PRFLAG ) THEN
                        K1 = P_EXIST ( V,N )
                        K2 = PR_EXIST( V,N )
                        IF( K2 .GT. 0 ) THEN
                            CALL APPLREAC( NPSRC, PNSREAC, K1, K2,  
     &                             PPRJFLAG, LMKTPON, PEISRC,PEMSRC,
     &                             PCRIDX, PCRREPEM, PCRPRJFC, 
     &                             PCRMKTPN, PCRFAC, PRINFO )
                        ELSE
                            PRINFO = 0.  ! array
                        END IF
                    END IF

C.....................  Process for point sources...
                    IF( PFLAG ) THEN

                        K1 = P_EXIST ( V,N )
                        K2 = PU_EXIST( V,N )
                        K3 = PA_EXIST( V,N )
                        K4 = PS_EXIST( V,N )
                        K5 = NGRID + NPSRC + 1

C.........................  Apply valid matrices & store
                        CALL MRGMULT( NPSRC, NGRID, EMLAYS, NPSRC, 
     &                         NPSRC, K1, K2, K3, K4, KP, F1, F2, 
     &                         PEMSRC, PRINFO, PCUMATX, PCAMATX, PSMATX, 
     &                         PGMATX(1), PGMATX(NGRID+1),
     &                         PGMATX(K5), PICNY, PEMGRD, TEMGRD,
     &                         PEBCNY, PEUCNY, PEACNY, PERCNY, 
     &                         PECCNY )

C.........................  Apply matrices for plume-in-grid outputs
                        IF( PINGFLAG ) THEN
                            CALL MRGPING( NPSRC, NPING, K1, K2, 
     &                                    K3, K4 )
                        END IF

                    END IF

C.....................  Check the flag that indicates the entries for which
C                       we need to output the gridded data
                    IF( GVLOUT( V,N ) ) THEN

C.........................  Write out gridded data
                        CALL WMRGEMIS( SBUF, JDATE, JTIME )

C.........................  Initialize gridded arrays
                        IF( AFLAG ) THEN
                            AEMGRD = 0.  ! array
                        ENDIF

                        IF( MFLAG ) THEN
                            MEMGRD = 0.  ! array
                        ENDIF

                        IF( PFLAG ) THEN
                            PEMGRD = 0.  ! array
                        ENDIF

                        TEMGRD = 0.      ! array
                    END IF 

                END DO      ! End loop on variables in group

C.................  Write country, state, and county emissions (all that apply) 
C.................  The subroutine will only write for certain hours and 
C                   will reinitialize the totals after output
                IF( LREPANY ) THEN
                    CALL WRMRGREP( JDATE, JTIME, N )
                END IF

                LDATE = JDATE

                CALL NEXTIME( JDATE, JTIME, TSTEP )     !  update model clock

            END DO          ! End loop on time steps

        END DO   ! End of loop on pollutant/pol-to-spcs groups

C.........  Successful completion of program
        CALL M3EXIT( PROGNAME, 0, 0, ' ', 0 )


C******************  FORMAT  STATEMENTS   ******************************

C...........   Formatted file I/O formats............ 93xxx

93020   FORMAT( 8X, 'at time ', A8 )

C...........   Internal buffering formats............ 94xxx

94000   FORMAT( A )

94010   FORMAT( 10 ( A, :, I10, :, 2X ) )

94020   FORMAT( A, I4, 2X, 10 ( A, :, 1PG14.6, :, 2X ) )

94030   FORMAT( 8X, 'at time ', A8 )

        END PROGRAM SMKMERGE

