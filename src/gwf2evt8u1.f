      MODULE GWFEVTMODULE
        INTEGER, SAVE, POINTER    ::NEVTOP,IEVTCB,MXNDEVT,INIEVT,NIEVT,
     1        mxznevt
        INTEGER, SAVE, POINTER    ::NPEVT,IEVTPF
        REAL,    SAVE,   DIMENSION(:),  ALLOCATABLE      ::EVTR
        REAL,    SAVE,   DIMENSION(:),  ALLOCATABLE      ::EXDP
        REAL,    SAVE,   DIMENSION(:),  ALLOCATABLE      ::SURF
        REAL,    SAVE,   DIMENSION(:),  ALLOCATABLE      ::EVTF
        REAL,    SAVE,   DIMENSION(:),  ALLOCATABLE      ::ETFACTOR
        INTEGER, SAVE,   DIMENSION(:),  ALLOCATABLE      ::IEVT,iznevt
      END MODULE GWFEVTMODULE



      SUBROUTINE GWF2EVT8U1AR(IN,INBCT)
C     ******************************************************************
C     ALLOCATE ARRAY STORAGE FOR EVAPOTRANSPIRATION
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,      ONLY:IOUT,NCOL,NROW,IFREFM,NODLAY,IUNSTR
      USE GWFEVTMODULE,ONLY:NEVTOP,IEVTCB,NPEVT,IEVTPF,EVTR,EXDP,SURF,
     1      IEVT,MXNDEVT,INIEVT,NIEVT,EVTF,ETFACTOR,iznevt,mxznevt
      USE GWTBCTMODULE, ONLY: MCOMP
C
      CHARACTER*200 LINE
      CHARACTER*4 PTYP
C     ------------------------------------------------------------------
C
C1------ALLOCATE SCALAR VARIABLES.
      ALLOCATE(NEVTOP,IEVTCB,MXNDEVT,INIEVT,NIEVT,mxznevt)
      ALLOCATE(NPEVT,IEVTPF)
C
C2------IDENTIFY PACKAGE.
      IEVTPF=0
      WRITE(IOUT,1)IN
    1 FORMAT(1X,/1X,'EVT -- EVAPOTRANSPIRATION PACKAGE, VERSION 7,',
     1     ' 5/2/2005',/,9X,'INPUT READ FROM UNIT ',I4)
C
C3------READ ET OPTION (NEVTOP) AND UNIT OR FLAG FOR CELL-BY-CELL FLOW
C3------TERMS (IEVTCB).
      CALL URDCOM(IN,IOUT,LINE)
      CALL UPARARRAL(IN,IOUT,LINE,NPEVT)
      IF(INBCT.GT.0)THEN
      IF(IFREFM.EQ.0) THEN
         READ(LINE,'(3I10)') NEVTOP,IEVTCB,IETFACTOR
       ELSE
         LLOC=1
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NEVTOP,R,IOUT,IN)
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IEVTCB,R,IOUT,IN)
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IETFACTOR,R,IOUT,IN)
      END IF
      ELSE
      IF(IFREFM.EQ.0) THEN
         READ(LINE,'(2I10)') NEVTOP,IEVTCB
       ELSE
         LLOC=1
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NEVTOP,R,IOUT,IN)
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IEVTCB,R,IOUT,IN)
      END IF
      ENDIF
C
      IF(IUNSTR.EQ.1.AND.NEVTOP.EQ.2)THEN
        READ(IN,*) MXNDEVT
      ELSE
        MXNDEVT = NODLAY(1)
      ENDIF
C
C4------CHECK TO SEE THAT ET OPTION IS LEGAL.
      IF(NEVTOP.GE.1.AND.NEVTOP.LE.3)GO TO 200
C
C4A-----OPTION IS ILLEGAL -- PRINT A MESSAGE & ABORT SIMULATION.
      WRITE(IOUT,8) NEVTOP
    8 FORMAT(1X,'ILLEGAL ET OPTION CODE (NEVTOP = ',I5,
     1       ') -- SIMULATION ABORTING')
      CALL USTOP(' ')
C
C5------OPTION IS LEGAL -- PRINT THE OPTION CODE.
  200 IF(NEVTOP.EQ.1) WRITE(IOUT,201)
  201 FORMAT(1X,'OPTION 1 -- EVAPOTRANSPIRATION FROM TOP LAYER')
      IF(NEVTOP.EQ.2) WRITE(IOUT,202)
  202 FORMAT(1X,'OPTION 2 -- EVAPOTRANSPIRATION FROM ONE SPECIFIED',
     1   ' NODE IN EACH VERTICAL COLUMN')
      IF(NEVTOP.EQ.3) WRITE(IOUT,203)
  203 FORMAT(1X,'OPTION 3 -- EVAPOTRANSPIRATION FROM HIGHEST ACTIVE',
     1   ' NODE IN EACH VERTICAL COLUMN')
C
C6------IF CELL-BY-CELL FLOWS ARE TO BE SAVED, THEN PRINT UNIT NUMBER.
      IF(IEVTCB.GT.0) WRITE(IOUT,204) IEVTCB
  204 FORMAT(1X,'CELL-BY-CELL FLOWS WILL BE SAVED ON UNIT ',I4)
C
C7------ALLOCATE SPACE FOR THE ARRAYS EVTR, EXDP, SURF, AND IEVT.
      ALLOCATE (EVTR(MXNDEVT))
      ALLOCATE (EXDP(MXNDEVT))
      ALLOCATE (SURF(MXNDEVT))
      ALLOCATE (IEVT(MXNDEVT))
c      ALLOCATE (iznevt(MXNDEVT))
      ALLOCATE (iznevt(1))
      evtr = 0
      iznevt = 0
      mxznevt = 0
C-----IF TRANSPORT IS ACTIVE THEN ALLOCATE ARRAYS AND READ ET FACTORS
      IF(INBCT.GT.0)THEN
        ALLOCATE (EVTF(MXNDEVT))
        ALLOCATE (ETFACTOR(MCOMP))
C
        IF(IETFACTOR.EQ.0)THEN !FILL ETFACTOR ARRAY
          DO I=1,MCOMP
            ETFACTOR(I) = 0.0
          ENDDO
        ELSE                  !READ ETFRACTOR ARRAY
          IF(IFREFM.EQ.0)THEN
            READ(IN,300) (ETFACTOR(I), I=1,MCOMP)
300         FORMAT(20 F10.3)
          ELSE
            READ(IN,*) (ETFACTOR(I), I=1,MCOMP)
          ENDIF
        ENDIF
      ENDIF
C
C8------READ NAMED PARAMETERS
      WRITE(IOUT,5) NPEVT
    5 FORMAT(1X,//1X,I5,' Evapotranspiration parameters')
      IF(NPEVT.GT.0) THEN
         DO 20 K=1,NPEVT
         CALL UPARARRRP(IN,IOUT,N,0,PTYP,1,1,0)
         IF(PTYP.NE.'EVT') THEN
            WRITE(IOUT,7)
    7       FORMAT(1X,'Parameter type must be EVT')
            CALL USTOP(' ')
         END IF
   20    CONTINUE
      END IF
C
C9------RETURN
      RETURN
      END
      SUBROUTINE GWF2EVT8U1RP(IN)
C     ******************************************************************
C     READ EVAPOTRANSPIRATION DATA
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,      ONLY:IOUT,NCOL,NROW,NLAY,DELR,DELC,IFREFM,NODLAY,
     1  AREA,IUNSTR
      USE GWFEVTMODULE,ONLY:NEVTOP,NPEVT,IEVTPF,EVTR,EXDP,SURF,IEVT,
     1  INIEVT,NIEVT,iznevt,mxznevt
      REAL, DIMENSION(:,:),ALLOCATABLE  ::TEMP
      INTEGER, DIMENSION(:,:),ALLOCATABLE  ::ITEMP
C
      CHARACTER*24 ANAME(5)
      CHARACTER(LEN=200) line
C
      DATA ANAME(1) /'          ET LAYER INDEX'/
      DATA ANAME(2) /'              ET SURFACE'/
      DATA ANAME(3) /' EVAPOTRANSPIRATION RATE'/
      DATA ANAME(4) /'        EXTINCTION DEPTH'/
      DATA ANAME(5) /'      zone array for ets'/
C     ------------------------------------------------------------------
C2------IDENTIFY PACKAGE.
      WRITE(IOUT,1)IN
    1 FORMAT(1X,/1X,'EVT -- EVAPOTRANSPIRATION PACKAGE, VERSION 7,',
     1     ' 5/2/2005',/,9X,'INPUT READ FROM UNIT ',I4)
C
      ALLOCATE (TEMP(NCOL,NROW))
      ALLOCATE (ITEMP(NCOL,NROW))
C
C2------READ FLAGS SHOWING WHETHER DATA IS TO BE REUSED.
      lloc = 1
      INIZNEVT = 0
      CALL URDCOM(In, Iout, line)
      IF(IFREFM.EQ.0)THEN
        IF(NEVTOP.EQ.2) THEN
          READ(LINE,'(4I10)') INSURF,INEVTR,INEXDP,INIEVT
        ELSE
          READ(LINE,'(3I10)') INSURF,INEVTR,INEXDP
          INIEVT = NODLAY(1)
        ENDIF
      ELSE
        IF(NEVTOP.EQ.2) THEN
          CALL URWORD(line, lloc, istart, istop, 2, INSURF, r, Iout, In)
          CALL URWORD(line, lloc, istart, istop, 2, INEVTR, r, Iout, In)
          CALL URWORD(line, lloc, istart, istop, 2, INEXDP, r, Iout, In)
          CALL URWORD(line, lloc, istart, istop, 2, INIEVT, r, Iout, In)
        ELSE
          CALL URWORD(line, lloc, istart, istop, 2, INSURF, r, Iout, In)
          CALL URWORD(line, lloc, istart, istop, 2, INEVTR, r, Iout, In)
          CALL URWORD(line, lloc, istart, istop, 2, INEXDP, r, Iout, In)
          INIEVT = NODLAY(1)
        END IF
      ENDIF
      IF(INIEVT.GE.0) NIEVT = INIEVT
C
C3------TEST INSURF TO SEE WHERE SURFACE ELEVATION COMES FROM.
      IF(INSURF.LT.0) THEN
C
C3A------INSURF<0, SO REUSE SURFACE ARRAY FROM LAST STRESS PERIOD.
        WRITE(IOUT,3)
    3   FORMAT(1X,/1X,'REUSING SURF FROM LAST STRESS PERIOD')
      ELSE
C
C3B------INSURF=>0, SO READ SURFACE.
        IF(IUNSTR.EQ.0)THEN
          CALL U2DREL(TEMP,ANAME(2),NROW,NCOL,0,IN,IOUT)
          N=0
          DO I=1,NROW
          DO J=1,NCOL
            N=N+1
            SURF(N)=TEMP(J,I)
          ENDDO
          ENDDO
        ELSE
          CALL U2DREL(SURF,ANAME(2),1,NIEVT,0,IN,IOUT)
        ENDIF
      END IF
C
C4------TEST INEVTR TO SEE WHERE MAX ET RATE (EVTR) COMES FROM.
      IF(INEVTR.LT.0) THEN
C
C4A-----INEVTR<0, SO REUSE EVTR FROM LAST STRESS PERIOD.
        WRITE(IOUT,4)
    4   FORMAT(1X,/1X,'REUSING EVTR FROM LAST STRESS PERIOD')
      ELSE
       IF(IUNSTR.EQ.0)THEN
C
C4B-----INEVTR=>0, SO READ MAX ET RATE.
        IF(NPEVT.EQ.0) THEN
C
C4B1----THERE ARE NO PARAMETERS,SO READ EVTR USING U2DREL
          CALL U2DREL(TEMP,ANAME(3),NROW,NCOL,0,IN,IOUT)
        ELSE
C
C4B2----DEFINE EVTR USING PARAMETERS. INEVTR IS THE NUMBER OF
C4B2----PARAMETERS TO USE THIS STRESS PERIOD.
          CALL PRESET('EVT')
          WRITE(IOUT,33)
   33     FORMAT(1X,///1X,
     1      'EVTR array defined by the following parameters:')
          IF (INEVTR.EQ.0) THEN
            WRITE(IOUT,34)
   34       FORMAT(' ERROR: When parameters are defined for the EVT',
     &     ' Package, at least one parameter',/,' must be specified',
     &     ' each stress period -- STOP EXECUTION (GWF2EVT8U1RPSS)')
            CALL USTOP(' ')
          END IF
          CALL UPARARRSUB2(TEMP,NCOL,NROW,0,INEVTR,IN,IOUT,'EVT',
     1        ANAME(3),'EVT',IEVTPF)
        END IF
        N=0
        DO I=1,NROW
        DO J=1,NCOL
          N=N+1
          EVTR(N)=TEMP(J,I)
        ENDDO
        ENDDO
       ELSE ! READ EVTR FOR UNSTRUCTURED GRID
C
C4B-----INEVTR=>0, SO READ MAX ET RATE.
        IF(NPEVT.EQ.0) THEN
C
C4B1----THERE ARE NO PARAMETERS,SO READ EVTR USING U2DREL
          CALL U2DREL(EVTR,ANAME(3),1,NIEVT,0,IN,IOUT)
        ELSE
C
C4B2----DEFINE EVTR USING PARAMETERS. INEVTR IS THE NUMBER OF
C4B2----PARAMETERS TO USE THIS STRESS PERIOD.
          CALL PRESET('EVT')
          WRITE(IOUT,33)
          IF (INEVTR.EQ.0) THEN
            WRITE(IOUT,34)
            CALL USTOP(' ')
          END IF
          CALL UPARARRSUB2(EVTR,NIEVT,1,0,INEVTR,IN,IOUT,'EVT',
     1        ANAME(3),'EVT',IEVTPF)
        END IF
       ENDIF
C
      END IF
C
C6------TEST INEXDP TO SEE WHERE EXTINCTION DEPTH COMES FROM
      IF(INEXDP.LT.0) THEN
C
C6A------IF INEXDP<0 REUSE EXTINCTION DEPTH FROM LAST STRESS PERIOD
        WRITE(IOUT,5)
    5   FORMAT(1X,/1X,'REUSING EXDP FROM LAST STRESS PERIOD')
      ELSE
C
        IF(IUNSTR.EQ.0)THEN
C6B------IF INEXDP=>0 CALL MODULE U2DREL TO READ EXTINCTION DEPTH
          CALL U2DREL(TEMP,ANAME(4),NROW,NCOL,0,IN,IOUT)
          N=0
          DO I=1,NROW
          DO J=1,NCOL
            N=N+1
            EXDP(N)=TEMP(J,I)
          ENDDO
          ENDDO
        ELSE
          CALL U2DREL(EXDP,ANAME(4),1,NIEVT,0,IN,IOUT)
        ENDIF
      END IF
C
C7------IF OPTION(NEVTOP) IS 2 THEN WE NEED AN INDICATOR ARRAY.  TEST
C7------INIEVT TO SEE HOW TO DEFINE IEVT.
      IF(NEVTOP.EQ.2) THEN
        IF(INIEVT.LT.0) THEN
C
C7A------IF INIEVT<0 THEN REUSE LAYER INDICATOR ARRAY.
          WRITE(IOUT,2)
    2     FORMAT(1X,/1X,'REUSING IEVT FROM LAST STRESS PERIOD')
        ELSE
C
C7B------IF INIEVT=>0 THEN READ INDICATOR ARRAY.
          IF(IUNSTR.EQ.0)THEN
            CALL U2DINT(ITEMP,ANAME(1),NROW,NCOL,0,IN,IOUT)
            DO 57 IR=1,NROW
            DO 57 IC=1,NCOL
            IF(ITEMP(IC,IR).LT.1 .OR. ITEMP(IC,IR).GT.NLAY) THEN
              WRITE(IOUT,56) IC,IR,TEMP(IC,IR)
   56         FORMAT(/1X,'INVALID LAYER NUMBER IN IEVT FOR COLUMN',I4,
     1           '  ROW',I4,'  :',I4)
              CALL USTOP(' ')
            END IF
   57       CONTINUE
            N=0
            DO I=1,NROW
            DO J=1,NCOL
              N=N+1
               IEVT(N)= (ITEMP(J,I)-1)*NROW*NCOL + (I-1)*NCOL + J
            ENDDO
            ENDDO
            NIEVT = NROW*NCOL
          ELSE ! FOR UNSTRUCTURED GRID
            CALL U2DINT(IEVT,ANAME(1),1,NIEVT,0,IN,IOUT)
C----------------------------------------------------            
C ----------CHECK FOR IEVT BEING LARGER THAN NODES
            IFLAG = 0
            DO I=1,NIEVT
              IF(IEVT(I).GT.NODES)THEN
                IFLAG = IEVT(I)
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
        END IF
      ELSE !NEVTOP IS NOT 2 SO SET TOP LAYER OF NODES IN IEVT
        DO I=1,NIEVT
          IEVT(I) = I
        ENDDO
      END IF
C
C-------IF ETMAX RATE IS READ THEN MULTIPLY BY AREA TO GIVE FLUX
      IF(INEVTR.GE.0)THEN
C
C5------MULTIPLY MAX ET RATE BY CELL AREA TO GET VOLUMETRIC RATE
        DO 40 NN=1,NIEVT
          N = IEVT(NN)
          EVTR(NN)=EVTR(NN)*AREA(N)
   40   CONTINUE
      ENDIF
C----------------------------------------------------------------
C
      DEALLOCATE(TEMP)
      DEALLOCATE(ITEMP)
C8------RETURN
      RETURN
      END
      SUBROUTINE GWF2EVT8U1FM
C     ******************************************************************
C     ADD EVAPOTRANSPIRATION TO RHS AND HCOF
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,      ONLY:NCOL,NROW,NLAY,HNEW,RHS,AMAT,IA,JA,JAS,
     *                      IBOUND,NODLAY,IVC
      USE GWFEVTMODULE,ONLY:NEVTOP,EVTR,EXDP,SURF,IEVT,NIEVT
C
      DOUBLE PRECISION HH,SS,XX,DD
C     ------------------------------------------------------------------
C
C2------PROCESS EACH HORIZONTAL CELL LOCATION
      DO 10 NN=1,NIEVT
      N = IEVT(NN)
C---------------------------------------------------------
C-------FIND TOP-MOST ACTIVE NODE IF NOT N
        IF(NEVTOP.EQ.3.AND.IBOUND(N).EQ.0)THEN
          CALL FIRST_ACTIVE_BELOW(N)
        ENDIF
C---------------------------------------------------------
C
C5------IF THE CELL IS NOT VARIABLE HEAD, IGNORE IT.  IF CELL IS
C5------VARIABLE HEAD, GET DATA NEEDED TO COMPUTE FLOW TERMS.
    4 IF(IBOUND(N).LE.0)GO TO 10
      C=EVTR(NN)
      S=SURF(NN)
      SS=S
      HH=HNEW(N)
C
C6------IF AQUIFER HEAD IS GREATER THAN OR EQUAL TO SURF, ET IS CONSTANT
      IF(HH.LT.SS) GO TO 5
C
C6A-----HEAD IS GREATER THAN OR EQUAL TO SURF.  ADD EVTR TO RHS
      RHS(N)=RHS(N) + C
      GO TO 10
C
C7------IF DEPTH TO WATER>=EXTINCTION DEPTH, THEN ET IS 0.
    5 DD=SS-HH
      X=EXDP(NN)
      XX=X
      IF(DD.GE.XX)GO TO 10
C
C8------LINEAR RANGE. ADD ET TERMS TO BOTH RHS AND HCOF.
      RHS(N)=RHS(N)+C-C*S/X
      AMAT(IA(N))=AMAT(IA(N))-C/X
   10 CONTINUE
C
C9------RETURN
      RETURN
      END
      SUBROUTINE GWF2EVT8U1BD(KSTP,KPER,INBCT)
C     ******************************************************************
C     CALCULATE VOLUMETRIC BUDGET FOR EVAPOTRANSPIRATION
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,      ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,HNEW,BUFF,NODES,
     *                      IA,JA,NODLAY,IUNSTR,IVC
      USE GWFBASMODULE,ONLY:MSUM,VBVL,VBNM,ICBCFL,DELT,PERTIM,TOTIM
      USE GWFEVTMODULE,ONLY:NEVTOP,IEVTCB,EVTR,EXDP,SURF,IEVT,
     *  NIEVT,EVTF
C
      DOUBLE PRECISION RATOUT,QQ,HH,SS,DD,XX,HHCOF,RRHS
      INTEGER,ALLOCATABLE,DIMENSION(:,:) :: ITEMP
      INTEGER,ALLOCATABLE,DIMENSION(:) :: IBUFF
      CHARACTER*16 TEXT
      DATA TEXT /'              ET'/
C     ------------------------------------------------------------------
C
C2------CLEAR THE RATE ACCUMULATOR.
      ZERO=0.
      RATOUT=ZERO
C
C3------CLEAR THE BUFFER & SET CELL-BY-CELL BUDGET SAVE FLAG (IBD).
      DO 2 N=1,NODES
      BUFF(N)=ZERO
    2 CONTINUE
      IF(INBCT.GT.0)THEN
        DO N=1,NIEVT
          EVTF(N) = ZERO
        ENDDO
      ENDIF
      IBD=0
      IF(IEVTCB.GT.0) IBD=ICBCFL
      ALLOCATE(IBUFF(NIEVT))
C
C4------PROCESS EACH HORIZONTAL CELL LOCATION.
      DO 10 NN=1,NIEVT
      N = IEVT(NN)
C---------------------------------------------------------
C-------FIND TOP-MOST ACTIVE NODE IF NOT N
        IF(NEVTOP.EQ.3.AND.IBOUND(N).EQ.0)THEN
          CALL FIRST_ACTIVE_BELOW(N)
        ENDIF
        IBUFF(NN) = N
C
C7------IF CELL IS EXTERNAL THEN IGNORE IT.
      IF(IBOUND(N).LE.0)GO TO 10
      C=EVTR(NN)
      S=SURF(NN)
      SS=S
      HH=HNEW(N)
C
C8------IF AQUIFER HEAD => SURF,SET Q=MAX ET RATE.
      IF(HH.LT.SS) GO TO 7
      QQ=-C
      GO TO 9
C
C9------IF DEPTH=>EXTINCTION DEPTH, ET IS 0.
    7 X=EXDP(NN)
      XX=X
      DD=SS-HH
      IF(DD.GE.XX)GO TO 10
C
C10-----LINEAR RANGE. Q= -HNEW*EVTR/EXDP -EVTR + EVTR*SURF/EXDP.
      HHCOF=-C/X
      RRHS=(C*S/X)-C
      QQ=HH*HHCOF+RRHS
C
C11-----ACCUMULATE TOTAL FLOW RATE.
    9 Q=QQ
      RATOUT=RATOUT-QQ
C
C12-----ADD Q TO BUFFER.
      BUFF(N)=Q
      IF(INBCT.GT.0) EVTF(NN) = Q
   10 CONTINUE
C
C13-----IF CELL-BY-CELL FLOW TO BE SAVED, CALL APPROPRIATE UTILITY
C13-----MODULE SAVE THEM.
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.1) CALL UBUDSV(KSTP,KPER,TEXT,IEVTCB,BUFF,NCOL,NROW,
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
          CALL UBDSV3(KSTP,KPER,TEXT,IEVTCB,BUFF,ITEMP,NEVTOP,
     1                NCOL,NROW,NLAY,IOUT,DELT,PERTIM,TOTIM,IBOUND)
          DEALLOCATE(ITEMP)
        ENDIF
      ELSE
        IF(IBD.EQ.1) CALL UBUDSVU(KSTP,KPER,TEXT,IEVTCB,BUFF,NODES,
     1                          IOUT,PERTIM,TOTIM)
        IF(IBD.EQ.2) CALL UBDSV3U(KSTP,KPER,TEXT,IEVTCB,BUFF,IBUFF,
     1        NIEVT,NEVTOP,NODES,IOUT,DELT,PERTIM,TOTIM,IBOUND)
      ENDIF
C
C14-----MOVE TOTAL ET RATE INTO VBVL FOR PRINTING BY BAS1OT.
      ROUT=RATOUT
      VBVL(3,MSUM)=ZERO
      VBVL(4,MSUM)=ROUT
C
C15-----ADD ET(ET_RATE TIMES STEP LENGTH) TO VBVL.
      VBVL(2,MSUM)=VBVL(2,MSUM)+ROUT*DELT
C
C16-----MOVE BUDGET TERM LABELS TO VBNM FOR PRINT BY MODULE BAS1OT.
      VBNM(MSUM)=TEXT
C
C17-----INCREMENT BUDGET TERM COUNTER.
      MSUM=MSUM+1
      DEALLOCATE(IBUFF)
C
C18-----RETURN.
      RETURN
      END
      SUBROUTINE GWF2EVT8U1DA(INBCT)
C  Deallocate EVT MEMORY
      USE GWFEVTMODULE
C
        DEALLOCATE(NEVTOP)
        DEALLOCATE(IEVTCB)
        DEALLOCATE(NPEVT)
        DEALLOCATE(IEVTPF)
        DEALLOCATE(EVTR)
        DEALLOCATE(EXDP)
        DEALLOCATE(SURF)
        DEALLOCATE(IEVT)
        DEALLOCATE(INIEVT,NIEVT)
        IF(INBCT.GT.0)THEN
        DEALLOCATE(EVTF)
        DEALLOCATE(ETFACTOR)
        ENDIF
C
      RETURN
      END
