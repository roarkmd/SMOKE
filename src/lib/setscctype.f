
        LOGICAL FUNCTION SETSCCTYPE( TSCC )

C***********************************************************************
C  function body starts at line 68
C
C  DESCRIPTION:
C       Checks SCC code and resets parameters based on type
C
C  PRECONDITIONS REQUIRED:
C       CATEGORY type must be set in MODINFO
C       SCC must be 10-digits long and right-justified
C       8-digit SCCs must start with '00'
C
C  SUBROUTINES AND FUNCTIONS CALLED: none
C
C  REVISION  HISTORY:
C     7/03: Created by C. Seppanen
C
C***********************************************************************
C
C Project Title: Sparse Matrix Operator Kernel Emissions (SMOKE) Modeling
C                System
C File: @(#)$Id$
C
C COPYRIGHT (C) 2002, MCNC Environmental Modeling Center
C All Rights Reserved
C
C See file COPYRIGHT for conditions of use.
C
C Environmental Modeling Center
C MCNC
C P.O. Box 12889
C Research Triangle Park, NC  27709-2889
C
C smoke@emc.mcnc.org
C
C Pathname: $Source$
C Last updated: $Date$ 
C
C***********************************************************************

C.........  MODULES for public variables
C.........  This module contains the information about the source category
        USE MODINFO, ONLY: LSCCEND, RSCCBEG, SCCLEV1, SCCLEV2,
     &                     SCCLEV3, CATEGORY
            
        IMPLICIT NONE
       
C........  Function arguments
        CHARACTER(LEN=*), INTENT (IN) :: TSCC   ! SCC code

C........  Local variables and their descriptions:
        
        CHARACTER*16  :: PROGNAME = 'SETSCCTYPE' ! program name
        
C***********************************************************************
C   begin body of function SETSCCTYPE

        SETSCCTYPE = .FALSE.

C.........  Don't change any parameters if category is mobile
        IF( CATEGORY == 'MOBILE' ) RETURN

C.........  Check if first two digits of SCC are zero
        IF( TSCC( 1:2 ) == '00' ) THEN

C.............  Only set new values if needed and set flag
            IF( LSCCEND /= 5 ) THEN
                SETSCCTYPE = .TRUE.  ! flag indicates that values have been changed
                LSCCEND = 5
                RSCCBEG = 6
                SCCLEV1 = 3
                SCCLEV2 = 5
                SCCLEV3 = 8
            END IF
        ELSE
            IF( LSCCEND /= 7 ) THEN
                SETSCCTYPE = .TRUE.
                LSCCEND = 7
                RSCCBEG = 8
                SCCLEV1 = 2
                SCCLEV2 = 4
                SCCLEV3 = 7
            END IF
        END IF

        RETURN

C******************  FORMAT  STATEMENTS   ******************************

C...........   Formatted file I/O formats............ 93xxx

93000   FORMAT( A )  
      
C...........   Internal buffering formats............ 94xxx

94010   FORMAT( 10( A, :, I8, :, 1X ) )
       
        END FUNCTION SETSCCTYPE
