
        INTEGER FUNCTION GETNLIST( ILENGTH, STRING )

C***********************************************************************
C  function body starts at line 
C
C  DESCRIPTION:
C      This function counts the number of free-formatted strings in a list
C      of string that may or may not have quotes.  This is used to help
C      when a string is available for reading a series of values, but
C      no indication is available for the number of entries to read.
C
C  PRECONDITIONS REQUIRED:
C
C  SUBROUTINES AND FUNCTIONS CALLED:
C
C  REVISION  HISTORY:
C      Created by M. Houyoux 1/99
C
C****************************************************************************/
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

C...........   EXTERNAL FUNCTIONS and their descriptions:
        
        INTEGER         TRIMLEN

        EXTERNAL        TRIMLEN

C...........   SUBROUTINE ARGUMENTS
        INTEGER       ILENGTH     !  length of string
        CHARACTER*(*) STRING      !  description of source category

C...........   Array of 1-char strings for processing
        CHARACTER*1   ARRSTR( ILENGTH )

C...........   Other local variables
        INTEGER         I, L   !  counters and indices
        INTEGER         NCNT   !  count of fields

        LOGICAL      :: ALPHA  = .FALSE. !  true when within alpha-numeric 
        LOGICAL      :: DELIM  = .FALSE. !  true when within or past delimiter 
        LOGICAL      :: NUMBER = .FALSE. !  true when within number in string 
        LOGICAL      :: QUOTED = .FALSE. !  true when within quotes in string

        CHARACTER*1      CBUF          !  temporary buffer
        CHARACTER*1   :: DOUBLEQ = '"'
        CHARACTER*1   :: SINGLEQ = "'"  
        CHARACTER*1   :: PERIOD  = '.' 
        CHARACTER*1      QUOTVAL       !  value of starting quote 

        CHARACTER*16 :: PROGNAME = 'GETNLIST' ! program name

C***********************************************************************
C   begin body of function GETNLIST

        L = TRIMLEN( STRING )

C.........  Copy string into 1-char array
        DO I = 1, L
            ARRSTR( I ) = STRING( I:I )
        ENDDO

C.........  Process array of 1-char strings to count up fields.
        DO I = 1, ILENGTH

            CBUF = ARRSTR( I )

C.............  Waiting for next field...
            IF( DELIM ) THEN

                IF( CBUF .GE. 'A' .AND. CBUF .LE. 'Z' ) THEN
                    ALPHA = .TRUE.
                    DELIM = .FALSE.
                    NCNT  = NCNT + 1

                ELSEIF( CBUF .GE. '0' .AND. CBUF .LE. '9' ) THEN
                    NUMBER = .TRUE.
                    DELIM  = .FALSE.
                    NCNT   = NCNT + 1

                ELSEIF( CBUF .EQ. SINGLEQ ) THEN
                    QUOTED  = .TRUE.
                    DELIM   = .FALSE.
                    QUOTVAL = SINGLEQ
                    NCNT    = NCNT + 1

                ELSEIF( CBUF .EQ. DOUBLEQ ) THEN
                    QUOTED  = .TRUE.
                    DELIM   = .FALSE.
                    QUOTVAL = DOUBLEQ
                    NCNT    = NCNT + 1

                ENDIF  ! Else its another delimiter

C.............  In a quoted field, skip everything unless it is an end quote
            ELSEIF( QUOTED ) THEN

                IF( CBUF .EQ. QUOTVAL ) THEN
                    QUOTED  = .FALSE.
                    DELIM   = .TRUE.
                ENDIF

C.............  If start of field was a number, but adjacent character is a
C               alpha, then turn field into an alpha (periods would delimit)
            ELSEIF( NUMBER .AND. 
     &              CBUF .GE. 'A' .AND. CBUF .LE. 'Z' ) THEN
                ALPHA  = .TRUE.
                NUMBER = .FALSE.

C.............  If start of field was a number, and this is not a decimal or
C               another number, then end of number has been reached
            ELSEIF( NUMBER .AND. 
     &              CBUF .NE. PERIOD .AND.
     &            ( CBUF .LT. '0' .OR. CBUF .GT. '9' ) ) THEN
                NUMBER = .FALSE.
                DELIM  = .TRUE.

C.............  If start of field was an alpha, and this is not an 
C               alpha-numeric, then end of alpha has been reached.
            ELSEIF( ALPHA .AND.
     &              .NOT. ( CBUF .GE. 'A' .AND. CBUF .LE. 'Z' ) .AND.
     &              .NOT. ( CBUF .GE. '0' .AND. CBUF .LE. '9' ) ) THEN
                ALPHA = .FALSE.
                DELIM = .TRUE.

            ENDIF

        ENDDO

        GETNLIST = NCNT

        RETURN

C******************  FORMAT  STATEMENTS   ******************************

C...........   Internal buffering formats............ 94xxx

94010   FORMAT( 10( A, :, I8, :, 1X ) )

        END
