
        SUBROUTINE RDINVPOL( FILNAM, NSRC, VCNT, VNAMES, 
     &                       POLDAT, STATUS )

C***********************************************************************
C  subroutine body starts at line
C
C  DESCRIPTION:
C      Reads inventory pollutant-specific data for variables listed in VNAMES
C
C  PRECONDITIONS REQUIRED:
C
C  SUBROUTINES AND FUNCTIONS CALLED:
C
C  REVISION  HISTORY:
C
C**************************************************************************
C
C Project Title: Sparse Matrix Operator Kernel Emissions (SMOKE) Modeling
C                System
C File: @(#)$Id$
C
C COPYRIGHT (C) 1998, MCNC--North Carolina Supercomputing Center
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
C***************************************************************************

        IMPLICIT NONE

C...........   INCLUDE FILES:
        INCLUDE 'EMCNST3.EXT'   !  emissions constant parameters
        INCLUDE 'PARMS3.EXT'    !  I/O API parameters
        INCLUDE 'IODECL3.EXT'   !  I/O API function declarations
        INCLUDE 'FDESC3.EXT'    !  I/O API file description data structures.

C...........   EXTERNAL FUNCTIONS:
        INTEGER         TRIMLEN

        EXTERNAL        TRIMLEN

C...........   SUBROUTINE ARGUMENTS
        CHARACTER*(*)   FILNAM           ! Name of file being read	
        INTEGER         NSRC             ! Number of sources
        INTEGER         VCNT             ! Number of variables
        CHARACTER*(*)   VNAMES( VCNT )   ! Variable names
        REAL            POLDAT( NSRC,VCNT ) ! Pollutant-specific data
        INTEGER         STATUS           ! Exit status

C...........   Other local variables

        INTEGER         V  ! counters and indices

        INTEGER         JDATE, JTIME
        SAVE            JDATE, JTIME

        CHARACTER*16    VARBUF
        CHARACTER*300   MESG 

        CHARACTER(LEN=IOVLEN3) LFILE 
        DATA            LFILE / '-9' /
        SAVE            LFILE

        CHARACTER*16 :: PROGNAME = 'RDINVPOL' ! program name

C***********************************************************************
C   begin body of subroutine RDINVPOL

        STATUS = 0

        IF( FILNAM .NE. LFILE ) THEN

            IF( .NOT. DESC3( FILNAM ) ) THEN

                STATUS = 1
                MESG = 'Could not read description for "' //
     &                 FILNAM( 1:TRIMLEN( FILNAM ) ) // '"'
                CALL M3MSG2( MESG )
                RETURN

            ELSE

                LFILE = FILNAM
                JDATE = SDATE3D
                JTIME = STIME3D

            ENDIF

        ENDIF

        DO V = 1, VCNT

            VARBUF = VNAMES( V )
            IF( .NOT. READ3( FILNAM, VARBUF, ALLAYS3,
     &                       JDATE, JTIME, POLDAT( 1,V ) ) ) THEN
                STATUS = 1
                MESG = 'ERROR: Could not read "' //
     &                 VARBUF( 1:TRIMLEN( VARBUF ) ) // '" from file.'
                CALL M3MSG2( MESG )

            END IF

        ENDDO

        RETURN

C******************  FORMAT  STATEMENTS   ******************************

        END

