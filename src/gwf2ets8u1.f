C------------------------------------------------------------------------
C-----SEPTEMBER 2015. ETS PACKAGE
C------------------------------------------------------------------------
      MODULE GWFETSMODULE
        INTEGER,SAVE,POINTER ::NETSOP,IETSCB,NPETS,IETSPF,NETSEG,
     1  MXNDETS,INIETS,NIETS
        INTEGER,      SAVE, DIMENSION(:),   ALLOCATABLE ::IETS
        REAL,         SAVE, DIMENSION(:),   ALLOCATABLE ::ETSR
        REAL,         SAVE, DIMENSION(:),   ALLOCATABLE ::ETSX
        REAL,         SAVE, DIMENSION(:),   ALLOCATABLE ::ETSS
        REAL,         SAVE, DIMENSION(:,:), ALLOCATABLE ::PXDP
        REAL,         SAVE, DIMENSION(:,:), ALLOCATABLE ::PETM
        REAL,    SAVE,   DIMENSION(:),  ALLOCATABLE      ::ETSF
        REAL,    SAVE,   DIMENSION(:),  ALLOCATABLE      ::ESFACTOR
      END MODULE GWFETSMODULE

      SUBROUTINE GWF2ETS8U1AR(IN,INBCT)
C     ******************************************************************
C     ALLOCATE ARRAY STORAGE FOR EVAPOTRANSPIRATION SEGMENTS AND READ
C     PARAMETER DEFINITIONS
C     Modified 11/21/2001 to support parameter instances - ERB
C     Modified 8/17/2009 to support NETSOP=3 - ERB
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IOUT,NCOL,NROW,IFREFM,NODLAY,IUNSTR
      USE GWFETSMODULE, ONLY:NETSOP,IETSCB,NPETS,IETSPF,NETSEG,
     1                       IETS,ETSR,ETSX,ETSS,PXDP,PETM,
     1                       MXNDETS,INIETS,NIETS,ETSF,ESFACTOR
cdl      USE GWTBCTMODULE, ONLY: MCOMP
C
      INTEGER :: MCOMP=0
      CHARACTER*4 PTYP
      CHARACTER*200 LINE
C     ------------------------------------------------------------------
  500 FORMAT(1X,/
     &1X,'ETS8 -- EVAPOTRANSPIRATION SEGMENTS PACKAGE, VERSION 8,',
     &     ' 10/05/2015',/,9X,'INPUT READ FROM UNIT ',I4)
  510 FORMAT(
     &1X,I5,' SEGMENTS DEFINE EVAPOTRANSPIRATION RATE FUNCTION')
  520 FORMAT(' EVAPOTRANSPIRATION RATE FUNCTION IS LINEAR')
  530 FORMAT(
     &' ERROR: EVAPOTRANSPIRATION RATE FUNCTION MUST CONTAIN AT',/,
     &' LEAST ONE SEGMENT -- STOP EXECUTION (GWF2ETS8U1AR)')
  540 FORMAT(1X,'ILLEGAL ET OPTION CODE. SIMULATION ABORTING')
  541 FORMAT(1X,'ESFRACTION ARRAY WILL BE READ FOR SOLUTE FRACTION',
     &       1X,'LEAVING WITH WATER')
  542 FORMAT(1X,'ESFRACTION ARRAY FOR COMPONENTS 1 TO MCOMP'/1X,44('-')/
     &    20F10.4)
  550 FORMAT(1X,'OPTION 1 -- EVAPOTRANSPIRATION FROM TOP LAYER')
  560 FORMAT(1X,'OPTION 2 -- EVAPOTRANSPIRATION FROM ONE SPECIFIED',
     &   ' NODE IN EACH VERTICAL COLUMN')
  564 FORMAT(1X,'OPTION 3 -- EVAPOTRANSPIRATION FROM UPPERMOST ACTIVE ',
     &   'CELL')
  570 FORMAT(1X,'CELL-BY-CELL FLOWS WILL BE SAVED ON UNIT ',I4)
  580 FORMAT(1X,I10,' ELEMENTS IN RX ARRAY ARE USED BY ETS')
  590 FORMAT(1X,I10,' ELEMENTS IN IR ARRAY ARE USED BY ETS')
C
      ALLOCATE (NETSOP,IETSCB,NPETS,IETSPF,NETSEG,MXNDETS,INIETS,NIETS)
C
C1------IDENTIFY PACKAGE.
      IETSPF=20
      WRITE(IOUT,500)IN
C
C     READ COMMENT LINE(S) (ITEM 0)
      CALL URDCOM(IN,IOUT,LINE)
C
C2------READ ET OPTION (NETSOP), UNIT OR FLAG FOR CELL-BY-CELL FLOW
C       TERMS (IETSCB), NUMBER OF PARAMETERS (NPETS), AND NUMBER OF
C       SEGMENTS (NETSEG) (ITEM 1)
      IF(INBCT.GT.0)THEN
        IF (IFREFM.EQ.0) THEN
          READ(LINE,'(5I10)') NETSOP,IETSCB,NPETS,NETSEG,IESFACTOR
        ELSE
          LLOC=1
          CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NETSOP,R,IOUT,IN)
          CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IETSCB,R,IOUT,IN)
          CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NPETS,R,IOUT,IN)
          CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NETSEG,R,IOUT,IN)
          CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IESFACTOR,R,IOUT,IN)
        ENDIF
        IF(IESFACTOR.EQ.1)WRITE(IOUT,541)
      ELSE
        IF (IFREFM.EQ.0) THEN
          READ(LINE,'(4I10)') NETSOP,IETSCB,NPETS,NETSEG
        ELSE
          LLOC=1
          CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NETSOP,R,IOUT,IN)
          CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IETSCB,R,IOUT,IN)
          CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NPETS,R,IOUT,IN)
          CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NETSEG,R,IOUT,IN)
        ENDIF
      ENDIF
C2B--------READ NUMBER OF ETS NODES IF UNSTRUCTURED AND NETSOP=2
      IF(IUNSTR.EQ.1.AND.NETSOP.EQ.2)THEN
        READ(IN,*) MXNDETS
      ELSE
        MXNDETS = NODLAY(1)
      ENDIF
C
C3------CHECK TO SEE THAT ET OPTION IS LEGAL.
      IF (NETSOP.GE.1 .AND. NETSOP.LE.3) GO TO 10
C
C3A-----OPTION IS ILLEGAL -- PRINT A MESSAGE & ABORT SIMULATION.
      WRITE(IOUT,540)
      CALL USTOP(' ')
C
C4------OPTION IS LEGAL -- PRINT THE OPTION CODE.
   10 CONTINUE
      IF (NETSOP.EQ.1) WRITE(IOUT,550)
      IF (NETSOP.EQ.2) WRITE(IOUT,560)
      IF (NETSOP.EQ.3) WRITE(IOUT,564) ! Add option 3 ERB 5/8/2009
C
C5------IF CELL-BY-CELL FLOWS ARE TO BE SAVED, THEN PRINT UNIT NUMBER.
      IF (IETSCB.GT.0) WRITE(IOUT,570) IETSCB
C
C-----PRINT NUMBER OF PARAMETERS TO BE USED
      CALL UPARARRAL(-1,IOUT,LINE,NPETS)
C
C     PRINT MESSAGE IDENTIFYING NUMBER OF SEGMENTS IN ET VS. HEAD CURVE
      IF(NETSEG.GT.1) THEN
        WRITE(IOUT,510) NETSEG
      ELSEIF (NETSEG.EQ.1) THEN
        WRITE(IOUT,520)
      ELSE
        WRITE(IOUT,530)
        CALL USTOP(' ')
      ENDIF
C
C6------ALLOCATE SPACE FOR THE ARRAYS ETSR, ETSX, ETSS, PXDP, AND PETM.
      ALLOCATE (ETSR(MXNDETS))
      ALLOCATE (ETSX(MXNDETS))
      ALLOCATE (ETSS(MXNDETS))
      IF( NETSEG.GT.1) THEN
        ALLOCATE (PXDP(MXNDETS,NETSEG))
        ALLOCATE (PETM(MXNDETS,NETSEG))
      ELSE
        ALLOCATE (PXDP(1,1))
        ALLOCATE (PETM(1,1))
      END IF
C
C7------ALLOCATE SPACE FOR LAYER INDICATOR ARRAY (IETS) EVEN IF ET
C7------OPTION IS NOT 2.
      ALLOCATE (IETS(MXNDETS))
      ETSR = 0
C-----IF TRANSPORT IS ACTIVE THEN ALLOCATE ARRAYS AND READ ET FACTORS
      IF(INBCT.GT.0)THEN
        ALLOCATE (ETSF(MXNDETS))
        ALLOCATE (ESFACTOR(MCOMP))
C
        IF(IESFACTOR.EQ.0)THEN !FILL ESFACTOR ARRAY
          DO I=1,MCOMP
            ESFACTOR(I) = 0.0
          ENDDO
        ELSE                  !READ ETFRACTOR ARRAY
          IF(IFREFM.EQ.0)THEN
            READ(IN,300) (ESFACTOR(I), I=1,MCOMP)
300         FORMAT(20 F10.3)
          ELSE
            READ(IN,*) (ESFACTOR(I), I=1,MCOMP)
          ENDIF
          WRITE(IOUT,542)(ESFACTOR(I), I=1,MCOMP)
        ENDIF
      ENDIF
C
C-------READ NAMED PARAMETERS
      WRITE(IOUT,50) NPETS
   50 FORMAT(1X,//1X,I5,' Evapotranspiration segments parameters')
      IF (NPETS.GT.0) THEN
        DO100 K=1,NPETS
C         UPARARRRP READS PARAMETER NAME AND DEFINITION (ITEMS 2 AND 3)
          CALL UPARARRRP(IN,IOUT,N,0,PTYP,1,1,0)
          IF(PTYP.NE.'ETS') THEN
            WRITE(IOUT,57)
   57       FORMAT(1X,'Parameter type must be ETS')
            CALL USTOP(' ')
          ENDIF
  100   CONTINUE
      ENDIF
C
C8------RETURN
      RETURN
      END
      SUBROUTINE GWF2ETS8U1RP(IN)
C     ******************************************************************
C     READ EVAPOTRANSPIRATION DATA, AND PERFORM SUBSTITUTION USING
C     PARAMETER VALUES IF ETS PARAMETERS ARE DEFINED
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:NCOL,NROW,IOUT,DELR,DELC,IFREFM,NODLAY,
     1  AREA,IUNSTR
      USE GWFETSMODULE, ONLY:NETSOP,NETSEG,NPETS,IETSPF,
     1 IETS,ETSR,ETSX,ETSS,PXDP,PETM,INIETS,NIETS
      REAL, DIMENSION(:,:),ALLOCATABLE  ::TEMP
      INTEGER, DIMENSION(:,:),ALLOCATABLE  ::ITEMP
C
      CHARACTER*24 ANAME(6)
      DATA ANAME(1) /'   ET LAYER INDEX (IETS)'/
      DATA ANAME(2) /'       ET SURFACE (ETSS)'/
      DATA ANAME(3) /' EVAPOTRANS. RATE (ETSR)'/
      DATA ANAME(4) /' EXTINCTION DEPTH (ETSX)'/
      DATA ANAME(5) /'EXTINCT. DEP. PROPORTION'/
      DATA ANAME(6) /'      ET RATE PROPORTION'/
C     ------------------------------------------------------------------
C
C1------IDENTIFY PACKAGE.
      WRITE(IOUT,500)IN
  500 FORMAT(1X,/
     &1X,'ETS8 -- EVAPOTRANSPIRATION SEGMENTS PACKAGE, VERSION 8,',
     &     ' 10/05/2015',/,9X,'INPUT READ FROM UNIT ',I4)
C
      ALLOCATE (TEMP(NCOL,NROW))
      ALLOCATE (ITEMP(NCOL,NROW))
C
C1------READ FLAGS SHOWING WHETHER DATA FROM PREVIOUS STRESS PERIODS ARE
C       TO BE REUSED.
      IF (NETSEG.GT.1) THEN
        IF(NETSOP.EQ.2) THEN
          IF(IFREFM.EQ.0) THEN
            READ(IN,'(5I10)') INETSS,INETSR,INETSX,INIETS,INSGDF
          ELSE
            READ(IN,*) INETSS,INETSR,INETSX,INIETS,INSGDF
          ENDIF
        ELSE
          IF(IFREFM.EQ.0) THEN
            READ(IN,'(5I10)') INETSS,INETSR,INETSX,INIETS,INSGDF
          ELSE
            READ(IN,*) INETSS,INETSR,INETSX,INIETS,INSGDF
          ENDIF
          INIETS = NODLAY(1)
        ENDIF
      ELSE
        IF(NETSOP.EQ.2) THEN
          IF(IFREFM.EQ.0) THEN
            READ(IN,'(4I10)') INETSS,INETSR,INETSX,INIETS
          ELSE
            READ(IN,*) INETSS,INETSR,INETSX,INIETS
          ENDIF
        ELSE
          IF(IFREFM.EQ.0) THEN
            READ(IN,'(3I10)') INETSS,INETSR,INETSX
          ELSE
            READ(IN,*) INETSS,INETSR,INETSX
          ENDIF
          INIETS = NODLAY(1)
        ENDIF
      ENDIF
      IF(INIETS.GE.0) NIETS = INIETS
C
C2------TEST INETSS TO SEE WHERE SURFACE ELEVATION COMES FROM.
      IF (INETSS.LT.0) THEN
C2A------IF INETSS<0 THEN REUSE SURFACE ARRAY FROM LAST STRESS PERIOD
        WRITE(IOUT,10)
   10   FORMAT(1X,/1X,'REUSING ETSS FROM LAST STRESS PERIOD')
      ELSE
C3-------IF INETSS=>0 THEN READ SURFACE.
        IF(IUNSTR.EQ.0)THEN
          CALL U2DREL(TEMP,ANAME(2),NROW,NCOL,0,IN,IOUT)
          N=0
          DO I=1,NROW
          DO J=1,NCOL
            N=N+1
            ETSS(N)=TEMP(J,I)
          ENDDO
          ENDDO
        ELSE
          CALL U2DREL(ETSS,ANAME(2),1,NIETS,0,IN,IOUT)
        ENDIF
      ENDIF
C
C4------TEST INETSR TO SEE WHERE MAX ET RATE COMES FROM.
      IF (INETSR.LT.0) THEN
C4A-----IF INETSR<0 THEN REUSE MAX ET RATE.
        WRITE(IOUT,20)
   20   FORMAT(1X,/1X,'REUSING ETSR FROM LAST STRESS PERIOD')
      ELSE
       IF(IUNSTR.EQ.0)THEN
C5------IF INETSR=>0 CALL MODULE U2DREL TO READ MAX ET RATE.
        IF(NPETS.EQ.0) THEN
          CALL U2DREL(TEMP,ANAME(3),NROW,NCOL,0,IN,IOUT)
        ELSE
C    INETSR is the number of parameters to use this stress period
          CALL PRESET('ETS')
          WRITE(IOUT,30)
   30     FORMAT(1X,///1X,
     &        'ETSR array defined by the following parameters:')
          IF (INETSR.EQ.0) THEN
            WRITE(IOUT,35)
   35       FORMAT(' ERROR: When parameters are defined for the ETS',
     &      ' Package, at least one parameter',/,' must be specified',
     &      ' each stress period -- STOP EXECUTION (GWF2ETS7RPSS)')
            CALL USTOP(' ')
          ENDIF
          CALL UPARARRSUB2(TEMP,NCOL,NROW,0,INETSR,IN,IOUT,'ETS',
     &                     ANAME(3),'ETS',IETSPF)
        ENDIF
        N=0
        DO I=1,NROW
        DO J=1,NCOL
          N=N+1
          ETSR(N)=TEMP(J,I)
        ENDDO
        ENDDO
       ELSE ! READ ETSR FOR UNSTRUCTURED GRID
C5------IF INETSR=>0 CALL MODULE U2DREL TO READ MAX ET RATE.
        IF(NPETS.EQ.0) THEN
          CALL U2DREL(ETSR,ANAME(3),1,NIETS,0,IN,IOUT)
        ELSE
C    INETSR is the number of parameters to use this stress period
          CALL PRESET('ETS')
          WRITE(IOUT,30)
          IF (INETSR.EQ.0) THEN
            WRITE(IOUT,35)
            CALL USTOP(' ')
          ENDIF
          CALL UPARARRSUB2(ETSR,1,NIETS,0,INETSR,IN,IOUT,'ETS',
     &                     ANAME(3),'ETS',IETSPF)
        ENDIF
       ENDIF
      ENDIF
C
C7------TEST INETSX TO SEE WHERE EXTINCTION DEPTH COMES FROM
      IF (INETSX.LT.0) THEN
C7A------IF INETSX<0 REUSE EXTINCTION DEPTH FROM LAST STRESS PERIOD
        WRITE(IOUT,60)
   60   FORMAT(1X,/1X,'REUSING ETSX FROM LAST STRESS PERIOD')
      ELSE
       IF(IUNSTR.EQ.0)THEN
        CALL U2DREL(TEMP,ANAME(4),NROW,NCOL,0,IN,IOUT)
        N=0
        DO I=1,NROW
        DO J=1,NCOL
          N=N+1
          ETSX(N)=TEMP(J,I)
        ENDDO
        ENDDO
       ELSE
C8-------IF INETSX=>0 CALL MODULE U2DREL TO READ EXTINCTION DEPTH
        CALL U2DREL(ETSX,ANAME(4),1,NIETS,0,IN,IOUT)
       ENDIF
      ENDIF
C
C9------IF OPTION(NETSOP) IS 2 THEN WE NEED AN INDICATOR ARRAY.
      IF (NETSOP.EQ.2) THEN
C10------IF INIETS<0 THEN REUSE LAYER INDICATOR ARRAY.
        IF (INIETS.LT.0) THEN
          WRITE(IOUT,70)
   70     FORMAT(1X,/1X,'REUSING IETS FROM LAST STRESS PERIOD')
        ELSE
C7B------IF INIETS=>0 THEN READ INDICATOR ARRAY.
          IF(IUNSTR.EQ.0)THEN
            CALL U2DINT(ITEMP,ANAME(1),NROW,NCOL,0,IN,IOUT)
            DO 57 IR=1,NROW
            DO 57 IC=1,NCOL
            IF(ITEMP(IC,IR).LT.1 .OR. ITEMP(IC,IR).GT.NLAY) THEN
              WRITE(IOUT,56) IC,IR,TEMP(IC,IR)
   56         FORMAT(/1X,'INVALID LAYER NUMBER IN IETS FOR COLUMN',I4,
     1           '  ROW',I4,'  :',I4)
              CALL USTOP(' ')
            END IF
   57       CONTINUE
            N=0
            DO I=1,NROW
            DO J=1,NCOL
              N=N+1
              IETS(N)= (ITEMP(J,I)-1)*NROW*NCOL + (I-1)*NCOL + J
            ENDDO
            ENDDO
            NIETS = NROW*NCOL
          ELSE ! FOR UNSTRUCTURED GRID
C11------IF INIETS=>0 THEN CALL MODULE U2DINT TO READ INDICATOR ARRAY.
            CALL U2DINT(IETS,ANAME(1),1,NIETS,0,IN,IOUT)
C----------------------------------------------------            
C ----------CHECK FOR IETS BEING LARGER THAN NODES
            IFLAG = 0
            DO I=1,NIETS
              IF(IETS(I).GT.NODES)THEN
                IFLAG = IETS(I)
                GO TO 112
              ENDIF
            ENDDO
112         CONTINUE 
C ----------WRITE MESSAGE AND STOP IF IEVT IS LARGER THAN NODES
            IF(IFLAG.GT.0)THEN
              WRITE(IOUT,75)IFLAG,NODES 
75            FORMAT('INDEX NODE NO.',I10,
     1        ', LARGER THAN TOTAL GWF NODES (',I10,'), STOPPING')
              STOP
            ENDIF
C----------------------------------------------------             
          ENDIF
        ENDIF
      ELSE !NETSOP IS NOT 2 SO SET TOP LAYER OF NODES IN IETS
        DO I=1,NIETS
          IETS(I) = I
        ENDDO
      END IF
C
C-------IF ETMAX RATE IS READ THEN MULTIPLY BY AREA TO GIVE FLUX
      IF(INETSR.GE.0)THEN
C
C5------MULTIPLY MAX ET RATE BY CELL AREA TO GET VOLUMETRIC RATE
        DO 40 NN=1,NIETS
          N = IETS(NN)
          ETSR(NN)=ETSR(NN)*AREA(N)
   40   CONTINUE
      ENDIF
C----------------------------------------------------------------
C
C12------IF ET FUNCTION IS SEGMENTED PXDP AND PETM ARRAYS ARE NEEDED.
      IF (NETSEG.GT.1) THEN
C13------IF INSGDF<0 THEN REUSE PXDP AND PETM ARRAYS.
        IF (INSGDF.LT.0) THEN
          WRITE(IOUT,80)
   80     FORMAT(1X,/1X,
     &           'REUSING PXDP AND PETM FROM LAST STRESS PERIOD')
C14------IF INSGDF=>0 THEN CALL MODULE U2DREL TO READ PXDP AND PETM
C        ARRAYS.
        ELSE
         IF(IUNSTR.EQ.0)THEN
          DO 90 ISEG = 1,NETSEG-1
            WRITE(IOUT,100) ISEG
            CALL U2DREL(TEMP,ANAME(5),NROW,NCOL,0,IN,IOUT)
            N=0
            DO I=1,NROW
            DO J=1,NCOL
              N=N+1
              PXDP(N,ISEG)=TEMP(J,I)
            ENDDO
            ENDDO
C
            CALL U2DREL(TEMP,ANAME(6),NROW,NCOL,0,IN,IOUT)
            N=0
            DO I=1,NROW
            DO J=1,NCOL
              N=N+1
              PETM(N,ISEG)=TEMP(J,I)
            ENDDO
            ENDDO
C
   90     CONTINUE
         ELSE ! UNSTRUCTURED GRID
          DO 91 ISEG = 1,NETSEG-1
            WRITE(IOUT,100) ISEG
            CALL U2DREL(PXDP(:,ISEG),ANAME(5),1,NIETS,0,IN,IOUT)
            CALL U2DREL(PETM(:,ISEG),ANAME(6),1,NIETS,0,IN,IOUT)
   91     CONTINUE

         ENDIF
        ENDIF
      ENDIF
  100 FORMAT(/,' PXDP AND PETM ARRAYS FOR INTERSECTION ',I4,
     &' OF HEAD/ET RELATION:')
C
C----------------------------------------------------------------
C
      DEALLOCATE(TEMP)
      DEALLOCATE(ITEMP)
C
C15-----RETURN
      RETURN
      END
      SUBROUTINE GWF2ETS8U1FM
C     ******************************************************************
C        ADD EVAPOTRANSPIRATION TO RHS AND HCOF
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:NCOL,NROW,NLAY,RHS,IBOUND,HNEW,AMAT,IA,JA,
     *                  JAS,NODLAY,IVC
      USE GWFETSMODULE, ONLY:NETSOP,NETSEG,IETS,ETSR,ETSX,ETSS,PXDP,PETM
     *                  ,NIETS,IETS
C
      DOUBLE PRECISION HH, SS, XX, DD, PXDP1, PXDP2
C     ------------------------------------------------------------------
C
C1------PROCESS EACH HORIZONTAL CELL LOCATION
      DO 10 NN=1,NIETS
        N = IETS(NN)
C---------------------------------------------------------
C-------FIND TOP-MOST ACTIVE NODE IF NOT N
        IF(NETSOP.EQ.3.AND.IBOUND(N).EQ.0)THEN
          CALL FIRST_ACTIVE_BELOW(N)
        ENDIF
C---------------------------------------------------------
C
C5------IF THE CELL IS NOT VARIABLE HEAD, IGNORE IT.  IF CELL IS
C5------VARIABLE HEAD, GET DATA NEEDED TO COMPUTE FLOW TERMS.
        IF(IBOUND(N).LE.0)GO TO 10
        C=ETSR(NN)
        S=ETSS(NN)
        SS=S
        HH=HNEW(N)
C
C5------IF HEAD IN CELL IS GREATER THAN OR EQUAL TO ETSS, ET IS CONSTANT
        IF(HH.LT.SS) GO TO 5
C
C5A-----SUBTRACT -ETSR FROM RHS
        RHS(N)=RHS(N) + C
        GO TO 10
C
C6------IF DEPTH TO WATER>=EXTINCTION DEPTH THEN ET IS 0
5       DD=SS-HH
        X=ETSX(NN)
        XX=X
        IF (DD.GE.XX) GO TO 10
C7------VARIABLE RANGE. ADD ET TERMS TO BOTH RHS AND HCOF.
C
        IF (NETSEG.GT.1) THEN
C         DETERMINE WHICH SEGMENT APPLIES BASED ON HEAD, AND
C         CALCULATE TERMS TO ADD TO RHS AND HCOF
C
C         SET PROPORTIONS CORRESPONDING TO ETSS ELEVATION
          PXDP1 = 0.0
          PETM1 = 1.0
          DO 110 ISEG = 1,NETSEG
C           SET PROPORTIONS CORRESPONDING TO LOWER END OF
C           SEGMENT
            IF (ISEG.LT.NETSEG) THEN
              PXDP2 = PXDP(NN,ISEG)
              PETM2 = PETM(NN,ISEG)
            ELSE
              PXDP2 = 1.0
              PETM2 = 0.0
            ENDIF
            IF (DD.LE.PXDP2*XX) THEN
C             HEAD IS IN DOMAIN OF THIS SEGMENT
              GOTO 15
            ENDIF
C           PROPORTIONS AT LOWER END OF SEGMENT WILL BE FOR
C           UPPER END OF SEGMENT NEXT TIME THROUGH LOOP
            PXDP1 = PXDP2
            PETM1 = PETM2
  110      CONTINUE
   15     CONTINUE
C         CALCULATE TERMS TO ADD TO RHS AND HCOF BASED ON
C         SEGMENT THAT APPLIES AT HEAD ELEVATION
          THCOF = -(PETM1-PETM2)*C/((PXDP2-PXDP1)*X)
          TRHS = THCOF*(S-PXDP1*X) + PETM1*C
        ELSE
C         CALCULATE TERMS TO ADD TO RHS AND HCOF BASED ON SIMPLE
C         LINEAR RELATION OF ET VS. HEAD
          TRHS = C-C*S/X
          THCOF = -C/X
        ENDIF
        RHS(N)=RHS(N)+TRHS
        AMAT(IA(N)) = AMAT(IA(N))+THCOF
   10 CONTINUE
C
C8------RETURN
      RETURN
      END
      SUBROUTINE GWF2ETS8U1BD(KSTP,KPER,INBCT)
C     ******************************************************************
C     CALCULATE VOLUMETRIC BUDGET FOR EVAPOTRANSPIRATION SEGMENTS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL ,      ONLY: IOUT,HNEW,IBOUND,BUFF,NCOL,NROW,NLAY,
     *                  NODES,IA,JA,NODLAY,IUNSTR,IVC
      USE GWFBASMODULE, ONLY: MSUM,VBNM,VBVL,PERTIM,TOTIM,DELT,ICBCFL
      USE GWFETSMODULE, ONLY: NETSOP,IETSCB,NETSEG,IETS,ETSR,ETSX,ETSS,
     1                        PXDP,PETM,NIETS,IETS,ETSF
C
      DOUBLE PRECISION RATOUT, QQ, HH, SS, DD, XX, HHCOF, RRHS,
     &                 PXDP1, PXDP2
      CHARACTER*16 TEXT
      INTEGER,ALLOCATABLE,DIMENSION(:,:) :: ITEMP
      INTEGER,ALLOCATABLE,DIMENSION(:) :: IBUFF
      DATA TEXT /'     ET SEGMENTS'/
C     ------------------------------------------------------------------
C
C1------CLEAR THE RATE ACCUMULATOR.
      ZERO=0.
      RATOUT=ZERO
C
C2------SET CELL-BY-CELL BUDGET SAVE FLAG (IBD) AND CLEAR THE BUFFER.
      DO 2 N=1,NODES
      BUFF(N)=ZERO
    2 CONTINUE
      IF(INBCT.GT.0)THEN
        DO N=1,NIETS
          ETSF(N) = ZERO
        ENDDO
      ENDIF
      IBD=0
      IF(IETSCB.GT.0) IBD=ICBCFL
      ALLOCATE(IBUFF(NIETS))
C
C3------PROCESS EACH HORIZONTAL CELL LOCATION.
      DO 10 NN=1,NIETS
        N = IETS(NN)
C---------------------------------------------------------
C-------FIND TOP-MOST ACTIVE NODE IF NOT N
        IF(NETSOP.EQ.3.AND.IBOUND(N).EQ.0)THEN
          CALL FIRST_ACTIVE_BELOW(N)
        ENDIF
        IBUFF(NN) = N
C
C6------IF CELL IS EXTERNAL THEN IGNORE IT.
        IF (IBOUND(N).LE.0) GO TO 10
        C=ETSR(NN)
        S=ETSS(NN)
        SS=S
        HH=HNEW(N)
C
C7------IF HEAD IN CELL => ETSS,SET Q=MAX ET RATE.
        IF (HH.LT.SS) GO TO 7
        QQ=-C
        GO TO 9
C
C8------IF DEPTH=>EXTINCTION DEPTH, ET IS 0.
7       CONTINUE
        X=ETSX(NN)
        XX=X
        DD=SS-HH
        IF (DD.GE.XX) GO TO 10
C9------VARIABLE RANGE.  CALCULATE Q DEPENDING ON NUMBER OF SEGMENTS
C
        IF (NETSEG.GT.1) THEN
C         DETERMINE WHICH SEGMENT APPLIES BASED ON HEAD, AND
C         CALCULATE TERMS TO ADD TO RHS AND HCOF
C
C         SET PROPORTIONS CORRESPONDING TO ETSS ELEVATION
          PXDP1 = 0.0
          PETM1 = 1.0
          DO 40 ISEG = 1,NETSEG
C           SET PROPORTIONS CORRESPONDING TO LOWER END OF
C           SEGMENT
            IF (ISEG.LT.NETSEG) THEN
              PXDP2 = PXDP(NN,ISEG)
              PETM2 = PETM(NN,ISEG)
            ELSE
              PXDP2 = 1.0
              PETM2 = 0.0
            ENDIF
            IF (DD.LE.PXDP2*XX) THEN
C             HEAD IS IN DOMAIN OF THIS SEGMENT
              GOTO 50
            ENDIF
C           PROPORTIONS AT LOWER END OF SEGMENT WILL BE FOR
C           UPPER END OF SEGMENT NEXT TIME THROUGH LOOP
            PXDP1 = PXDP2
            PETM1 = PETM2
   40     CONTINUE
   50     CONTINUE
C9------CALCULATE ET RATE BASED ON SEGMENT THAT APPLIES AT HEAD
C9------ELEVATION
          HHCOF = -(PETM1-PETM2)*C/((PXDP2-PXDP1)*X)
          RRHS = -HHCOF*(S-PXDP1*X) - PETM1*C
        ELSE
C10-------SIMPLE LINEAR RELATION.  Q=-ETSR*(HNEW-(ETSS-ETSX))/ETSX, WHICH
C10-------IS FORMULATED AS Q= -HNEW*ETSR/ETSX + (ETSR*ETSS/ETSX -ETSR).
          HHCOF = -C/X
          RRHS = (C*S/X) - C
        ENDIF
        QQ = HH*HHCOF + RRHS
C
C10-----ACCUMULATE TOTAL FLOW RATE.
9       CONTINUE
        Q=QQ
        RATOUT=RATOUT-QQ
C
C11-----ADD Q TO BUFFER.
        BUFF(N)=Q
        IF(INBCT.GT.0) ETSF(NN) = Q
   10 CONTINUE
C
C12-----IF CELL-BY-CELL FLOW TO BE SAVED, CALL APPROPRIATE UTILITY
C12-----MODULE SAVE THEM.
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.1) CALL UBUDSV(KSTP,KPER,TEXT,IETSCB,BUFF,NCOL,NROW,
     1                          NLAY,IOUT)
        IF(IBD.EQ.2) THEN
          ALLOCATE(ITEMP(NCOL,NROW))
          N=0
          DO I=1,NROW
            DO J=1,NCOL
              N=N+1
              ITEMP(J,I)= (IBUFF(N)-1) / (NCOL*NROW) + 1
            ENDDO
          ENDDO
          CALL UBDSV3(KSTP,KPER,TEXT,IETSCB,BUFF,ITEMP,NETSOP,
     1                NCOL,NROW,NLAY,IOUT,DELT,PERTIM,TOTIM,IBOUND)
          DEALLOCATE(ITEMP)
        ENDIF
      ELSE
        IF(IBD.EQ.1) CALL UBUDSVU(KSTP,KPER,TEXT,IETSCB,BUFF,NODES,
     1                          IOUT,PERTIM,TOTIM)
        IF(IBD.EQ.2) CALL UBDSV3U(KSTP,KPER,TEXT,IETSCB,BUFF,IBUFF,
     1        NIETS,NETSOP,NODES,IOUT,DELT,PERTIM,TOTIM,IBOUND)
      ENDIF
C
C13-----MOVE TOTAL ET RATE INTO VBVL FOR PRINTING BY BAS1OT.
      ROUT=RATOUT
      VBVL(3,MSUM)=ZERO
      VBVL(4,MSUM)=ROUT
C
C14-----ADD ET(ET_RATE TIMES STEP LENGTH) TO VBVL.
      VBVL(2,MSUM)=VBVL(2,MSUM)+ROUT*DELT
C
C15-----MOVE BUDGET TERM LABELS TO VBNM FOR PRINT BY MODULE BAS1OT.
      VBNM(MSUM)=TEXT
C
C16-----INCREMENT BUDGET TERM COUNTER.
      MSUM=MSUM+1
      DEALLOCATE(IBUFF)
C
C17-----RETURN.
      RETURN
      END
      SUBROUTINE GWF2ETS8U1DA(INBCT)
C  Deallocate ETS MEMORY
      USE GWFETSMODULE
C
        DEALLOCATE(NETSOP)
        DEALLOCATE(IETSCB)
        DEALLOCATE(NPETS)
        DEALLOCATE(IETSPF)
        DEALLOCATE(NETSEG)
        DEALLOCATE(IETS)
        DEALLOCATE(ETSR)
        DEALLOCATE(ETSX)
        DEALLOCATE(ETSS)
        DEALLOCATE(PXDP)
        DEALLOCATE(PETM)
        IF(INBCT.GT.0)THEN
          DEALLOCATE(ETSF)
          DEALLOCATE(ESFACTOR)
        ENDIF
C
      RETURN
      END
