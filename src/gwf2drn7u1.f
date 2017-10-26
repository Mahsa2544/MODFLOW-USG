      MODULE GWFDRNMODULE
        INTEGER,SAVE,POINTER  ::NDRAIN,MXDRN,NDRNVL,IDRNCB,IPRDRN
        INTEGER,SAVE,POINTER  ::NPDRN,IDRNPB,NNPDRN
        CHARACTER(LEN=16),SAVE, DIMENSION(:),   ALLOCATABLE     ::DRNAUX
        REAL,             SAVE, DIMENSION(:,:), ALLOCATABLE     ::DRAI
      TYPE GWFDRNTYPE
        INTEGER,POINTER  ::NDRAIN,MXDRN,NDRNVL,IDRNCB,IPRDRN
        INTEGER,POINTER  ::NPDRN,IDRNPB,NNPDRN
        CHARACTER(LEN=16), DIMENSION(:),   ALLOCATABLE     ::DRNAUX
        REAL,              DIMENSION(:,:), ALLOCATABLE     ::DRAI
      END TYPE
      TYPE(GWFDRNTYPE), SAVE:: GWFDRNDAT(10)
      END MODULE GWFDRNMODULE



      SUBROUTINE GWF2DRN7U1AR(IN)
C     ******************************************************************
C     ALLOCATE ARRAY STORAGE FOR DRAINS AND READ PARAMETER DEFINITIONS
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IOUT,NCOL,NROW,NLAY,IFREFM,NODES,IUNSTR,
     1                       NEQS
      USE GWFDRNMODULE, ONLY:NDRAIN,MXDRN,NDRNVL,IDRNCB,IPRDRN,NPDRN,
     1                       IDRNPB,NNPDRN,DRNAUX,DRAI
      CHARACTER*200 LINE
C     ------------------------------------------------------------------
      ALLOCATE(NDRAIN,MXDRN,NDRNVL,IDRNCB,IPRDRN)
      ALLOCATE(NPDRN,IDRNPB,NNPDRN)
C
C1------IDENTIFY PACKAGE AND INITIALIZE NDRAIN.
      WRITE(IOUT,1)IN
    1 FORMAT(1X,/1X,'DRN -- DRAIN PACKAGE, VERSION 7, 5/2/2005',
     1' INPUT READ FROM UNIT ',I4)
      NDRAIN=0
      NNPDRN=0
C
C2------READ MAXIMUM NUMBER OF DRAINS AND UNIT OR FLAG FOR
C2------CELL-BY-CELL FLOW TERMS.
      CALL URDCOM(IN,IOUT,LINE)
      CALL UPARLSTAL(IN,IOUT,LINE,NPDRN,MXPD)
      IF(IFREFM.EQ.0) THEN
         READ(LINE,'(2I10)') MXACTD,IDRNCB
         LLOC=21
      ELSE
         LLOC=1
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,MXACTD,R,IOUT,IN)
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IDRNCB,R,IOUT,IN)
      END IF
      WRITE(IOUT,3) MXACTD
    3 FORMAT(1X,'MAXIMUM OF ',I6,' ACTIVE DRAINS AT ONE TIME')
      IF(IDRNCB.LT.0) WRITE(IOUT,7)
    7 FORMAT(1X,'CELL-BY-CELL FLOWS WILL BE PRINTED WHEN ICBCFL NOT 0')
         IF(IDRNCB.GT.0) WRITE(IOUT,8) IDRNCB
    8 FORMAT(1X,'CELL-BY-CELL FLOWS WILL BE SAVED ON UNIT ',I4)
C
C3------READ AUXILIARY VARIABLES AND CBC ALLOCATION OPTION.
      ALLOCATE (DRNAUX(20))
      NAUX=0
      IPRDRN=1
   10 CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,IN)
      IF(LINE(ISTART:ISTOP).EQ.'AUXILIARY' .OR.
     1        LINE(ISTART:ISTOP).EQ.'AUX') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,IN)
         IF(NAUX.LT.20) THEN
            NAUX=NAUX+1
            DRNAUX(NAUX)=LINE(ISTART:ISTOP)
            WRITE(IOUT,12) DRNAUX(NAUX)
   12       FORMAT(1X,'AUXILIARY DRAIN VARIABLE: ',A)
         END IF
         GO TO 10
      ELSE IF(LINE(ISTART:ISTOP).EQ.'NOPRINT') THEN
         WRITE(IOUT,13)
   13    FORMAT(1X,'LISTS OF DRAIN CELLS WILL NOT BE PRINTED')
         IPRDRN = 0
         GO TO 10
      END IF
C3A-----THERE ARE FIVE INPUT DATA VALUES PLUS ONE LOCATION FOR
C3A-----CELL-BY-CELL FLOW.
      NDRNVL=6+NAUX
C
C4------ALLOCATE SPACE FOR DRAIN ARRAYs.
      IDRNPB=MXACTD+1
      MXDRN=MXACTD+MXPD
      ALLOCATE (DRAI(NDRNVL,MXDRN))
C
C5------READ NAMED PARAMETERS.
      WRITE(IOUT,1000) NPDRN
 1000 FORMAT(1X,//1X,I5,' Drain parameters')
      IF(NPDRN.GT.0) THEN
        LSTSUM=IDRNPB
        DO 120 K=1,NPDRN
          LSTBEG=LSTSUM
          CALL UPARLSTRP(LSTSUM,MXDRN,IN,IOUT,IP,'DRN','DRN',1,NUMINST)
          NLST=LSTSUM-LSTBEG
          IF(NUMINST.EQ.0) THEN
C5A-----READ PARAMETER WITHOUT INSTANCES
            IF(IUNSTR.EQ.0)THEN
              CALL ULSTRD(NLST,DRAI,LSTBEG,NDRNVL,MXDRN,1,IN,IOUT,
     &      'DRAIN NO.  LAYER   ROW   COL     DRAIN EL.  STRESS FACTOR',
     &        DRNAUX,5,NAUX,IFREFM,NCOL,NROW,NLAY,5,5,IPRDRN)
            ELSE
             CALL ULSTRDU(NLST,DRAI,LSTBEG,NDRNVL,MXDRN,1,IN,IOUT,
     1       'DRAIN NO.      NODE         DRAIN EL.  CONDUCTANCE',
     2       DRNAUX,5,NAUX,IFREFM,NEQS,5,5,IPRDRN)
            ENDIF
          ELSE
C5B-----READ INSTANCES
            NINLST=NLST/NUMINST
            DO 110 I=1,NUMINST
            CALL UINSRP(I,IN,IOUT,IP,IPRDRN)
            IF(IUNSTR.EQ.0)THEN
              CALL ULSTRD(NINLST,DRAI,LSTBEG,NDRNVL,MXDRN,1,IN,IOUT,
     &      'DRAIN NO.  LAYER   ROW   COL     DRAIN EL.  STRESS FACTOR',
     &        DRNAUX,20,NAUX,IFREFM,NCOL,NROW,NLAY,5,5,IPRDRN)
            ELSE
              CALL ULSTRDU(NINLST,DRAI,LSTBEG,NDRNVL,MXDRN,1,IN,IOUT,
     1        'DRAIN NO.      NODE         DRAIN EL.  CONDUCTANCE',
     2        DRNAUX,20,NAUX,IFREFM,NEQS,5,5,IPRDRN)
            ENDIF
            LSTBEG=LSTBEG+NINLST
  110       CONTINUE
          END IF
  120   CONTINUE
      END IF
C
C6------RETURN
      RETURN
      END
      SUBROUTINE GWF2DRN7U1RP(IN)
C     ******************************************************************
C     READ DRAIN HEAD, CONDUCTANCE AND BOTTOM ELEVATION
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IOUT,NCOL,NROW,NLAY,IFREFM,IUNSTR,NODES,
     1                       NEQS
      USE GWFDRNMODULE, ONLY:NDRAIN,MXDRN,NDRNVL,IPRDRN,NPDRN,
     1                       IDRNPB,NNPDRN,DRNAUX,DRAI
C     ------------------------------------------------------------------
C
C1------IDENTIFY PACKAGE.
      WRITE(IOUT,1)IN
    1 FORMAT(1X,/1X,'DRN -- DRAIN PACKAGE, VERSION 7, 5/2/2005',
     1' INPUT READ FROM UNIT ',I4)
C
C1------READ ITMP (NUMBER OF DRAINS OR FLAG TO REUSE DATA) AND
C1------NUMBER OF PARAMETERS.
55      IF(NPDRN.GT.0) THEN
         IF(IFREFM.EQ.0) THEN
            READ(IN,'(2I10)') ITMP,NP
         ELSE
            READ(IN,*) ITMP,NP
         END IF
      ELSE
         NP=0
         IF(IFREFM.EQ.0) THEN
            READ(IN,'(I10)') ITMP
         ELSE
            READ(IN,*) ITMP
         END IF
      END IF
C
C------CALCULATE SOME CONSTANTS
      NAUX=NDRNVL-6
      IOUTU = IOUT
      IF(IPRDRN.EQ.0) IOUTU=-IOUT
C
C2------DETERMINE THE NUMBER OF NON-PARAMETER DRAINS.
      IF(ITMP.LT.0) THEN
         WRITE(IOUT,7)
    7    FORMAT(1X,/1X,
     1        'REUSING NON-PARAMETER DRAINS FROM LAST STRESS PERIOD')
      ELSE
         NNPDRN=ITMP
      END IF
C
C3------IF THERE ARE NEW NON-PARAMETER DRAINS, READ THEM.
      MXACTD=IDRNPB-1
      IF(ITMP.GT.0) THEN
         IF(NNPDRN.GT.MXACTD) THEN
            WRITE(IOUT,99) NNPDRN,MXACTD
   99       FORMAT(1X,/1X,'THE NUMBER OF ACTIVE DRAINS (',I6,
     1                     ') IS GREATER THAN MXACTD(',I6,')')
            CALL USTOP(' ')
         END IF
         IF(IUNSTR.EQ.0)THEN
           CALL ULSTRD(NNPDRN,DRAI,1,NDRNVL,MXDRN,1,IN,IOUT,
     1     'DRAIN NO.  LAYER   ROW   COL     DRAIN EL.  CONDUCTANCE',
     2     DRNAUX,20,NAUX,IFREFM,NCOL,NROW,NLAY,5,5,IPRDRN)
         ELSE
           CALL ULSTRDU(NNPDRN,DRAI,1,NDRNVL,MXDRN,1,IN,IOUT,
     1     'DRAIN NO.      NODE         DRAIN EL.  CONDUCTANCE',
     2     DRNAUX,20,NAUX,IFREFM,NEQS,5,5,IPRDRN)
         ENDIF
      END IF
      NDRAIN=NNPDRN
C
C1C-----IF THERE ARE ACTIVE DRN PARAMETERS, READ THEM AND SUBSTITUTE
      CALL PRESET('DRN')
      IF(NP.GT.0) THEN
         NREAD=NDRNVL-1
         DO 30 N=1,NP
         CALL UPARLSTSUB(IN,'DRN',IOUTU,'DRN',DRAI,NDRNVL,MXDRN,NREAD,
     1                MXACTD,NDRAIN,5,5,
     2     'DRAIN NO.  LAYER   ROW   COL     DRAIN EL.  CONDUCTANCE',
     3            DRNAUX,20,NAUX)
   30    CONTINUE
      END IF
C
C3------PRINT NUMBER OF DRAINS IN CURRENT STRESS PERIOD.
      WRITE (IOUT,101) NDRAIN
  101 FORMAT(1X,/1X,I6,' DRAINS')
C
C-------FOR STRUCTURED GRID, CALCULATE NODE NUMBER AND PLACE IN LAYER LOCATION
C       ONLY NEEDS TO BE DONE FOR NON-PARAMETER DRAINS
      IF(ITMP.GT.0.AND.IUNSTR.EQ.0)THEN
        DO L=1,NNPDRN
          IR=DRAI(2,L)
          IC=DRAI(3,L)
          IL=DRAI(1,L)
          N = IC + NCOL*(IR-1) + (IL-1)* NROW*NCOL
          DRAI(1,L) = N
        ENDDO
      ENDIF
C
C8------RETURN.
      RETURN
      END
      SUBROUTINE GWF2DRN7U1FM
C     ******************************************************************
C     ADD DRAIN FLOW TO SOURCE TERM
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IBOUND,HNEW,RHS,AMAT,IA
      USE GWFDRNMODULE, ONLY:NDRAIN,DRAI
C
      DOUBLE PRECISION EEL,EL,C
C     ------------------------------------------------------------------
C
C1------IF NDRAIN<=0 THERE ARE NO DRAINS. RETURN.
      IF(NDRAIN.LE.0) RETURN
C
C2------PROCESS EACH CELL IN THE DRAIN LIST.
      DO 100 L=1,NDRAIN
C
C3------GET COLUMN, ROW AND LAYER OF CELL CONTAINING DRAIN.
      N=DRAI(1,L)
C
C4-------IF THE CELL IS EXTERNAL SKIP IT.
      IF(IBOUND(N).LE.0) GO TO 100
C
C5-------IF THE CELL IS INTERNAL GET THE DRAIN DATA.
      EL=DRAI(4,L)
      EEL=EL
C
C6------IF HEAD IS LOWER THAN DRAIN THEN SKIP THIS CELL.
      IF(HNEW(N).LE.EEL) GO TO 100
C
C7------HEAD IS HIGHER THAN DRAIN. ADD TERMS TO RHS AND HCOF.
      C=DRAI(5,L)
      AMAT(IA(N))=AMAT(IA(N))-C
      RHS(N)=RHS(N)-C*EL
  100 CONTINUE
C
C8------RETURN.
      RETURN
      END
      SUBROUTINE GWF2DRN7U1BD(KSTP,KPER)
C     ******************************************************************
C     CALCULATE VOLUMETRIC BUDGET FOR DRAINS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,      ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,HNEW,BUFF,IUNSTR,
     *                 NODES,NEQS,INCLN
      USE CLN1MODULE,  ONLY:NCLNNDS,ICLNCB 
      USE GWFBASMODULE,ONLY:MSUM,ICBCFL,IAUXSV,DELT,PERTIM,TOTIM,
     1                      VBVL,VBNM
      USE GWFDRNMODULE,ONLY:NDRAIN,IDRNCB,DRAI,NDRNVL,DRNAUX
C
      CHARACTER*16 TEXT
      DOUBLE PRECISION HHNEW,EEL,CCDRN,CEL,RATOUT,QQ,ROUT,EL,C
C
      DATA TEXT /'          DRAINS'/
C     ------------------------------------------------------------------
C
C1------INITIALIZE CELL-BY-CELL FLOW TERM FLAG (IBD) AND
C1------ACCUMULATOR (RATOUT).
      ZERO=0.
      RATOUT=ZERO
      IBD=0
      IF(IDRNCB.LT.0 .AND. ICBCFL.NE.0) IBD=-1
      IF(IDRNCB.GT.0) IBD=ICBCFL
      IBDLBL=0
C
C2------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A LIST, WRITE HEADER.
      IF(IBD.EQ.2) THEN
         NAUX=NDRNVL-6
         IF(IAUXSV.EQ.0) NAUX=0
        IICLNCB=0
        NNCLNNDS=0
        IF(INCLN.GT.0) THEN
          IICLNCB=ICLNCB
          NNCLNNDS=NCLNNDS
        ENDIF
         CALL UBDSVHDR(IUNSTR,KSTP,KPER,IOUT,IDRNCB,IICLNCB,NODES,
     1    NNCLNNDS,NCOL,NROW,NLAY,NDRAIN,NDRNVL,NAUX,IBOUND,
     2    TEXT,DRNAUX,DELT,PERTIM,TOTIM,DRAI)
      END IF
C
C3------CLEAR THE BUFFER.
      DO 50 N=1,NEQS
      BUFF(N)=ZERO
50    CONTINUE
C
C4------IF THERE ARE NO DRAINS THEN DO NOT ACCUMULATE DRAIN FLOW.
      IF(NDRAIN.LE.0) GO TO 200
C
C5------LOOP THROUGH EACH DRAIN CALCULATING FLOW.
      DO 100 L=1,NDRAIN
C
C5A-----GET LAYER, ROW & COLUMN OF CELL CONTAINING REACH.
      N=DRAI(1,L)
      Q=ZERO
      QQ = ZERO
C
C5B-----IF CELL IS NO-FLOW OR CONSTANT-HEAD, IGNORE IT.
      IF(IBOUND(N).LE.0) GO TO 99
C
C5C-----GET DRAIN PARAMETERS FROM DRAIN LIST.
      EL=DRAI(4,L)
      EEL=EL
      C=DRAI(5,L)
      HHNEW=HNEW(N)
C
C5D-----IF HEAD HIGHER THAN DRAIN, CALCULATE Q=C*(EL-HHNEW).
C5D-----SUBTRACT Q FROM RATOUT.
      IF(HHNEW.GT.EEL) THEN
         CCDRN=C
         CEL=C*EL
         QQ=CEL - CCDRN*HHNEW
         Q=QQ
         RATOUT=RATOUT-QQ
      END IF
C
C5E-----PRINT THE INDIVIDUAL RATES IF REQUESTED(IDRNCB<0).
      IF(IBD.LT.0) THEN
         IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT,KPER,KSTP
   61    FORMAT(1X,/1X,A,'   PERIOD ',I8,'   STEP ',I8)
        IF(IUNSTR.EQ.0)THEN         
          IL = (N-1) / (NCOL*NROW) + 1
          IJ = N - (IL-1)*NCOL*NROW
          IR = (IJ-1)/NCOL + 1
          IC = IJ - (IR-1)*NCOL
         WRITE(IOUT,62) L,IL,IR,IC,Q
   62    FORMAT(1X,'DRAIN ',I6,'   LAYER ',I3,'   ROW ',I5,'   COL ',I5,
     1       '   RATE ',1PG15.6)
        ELSE
          WRITE(IOUT,63) L,N,Q
   63    FORMAT(1X,'DRAIN ',I6,'    NODE ',I8, '   RATE ',1PG15.6)
        ENDIF
         IBDLBL=1
      END IF
C
C5F-----ADD Q TO BUFFER.
      BUFF(N)=BUFF(N)+QQ
C
C5G-----IF SAVING CELL-BY-CELL FLOWS IN A LIST, WRITE FLOW.  ALSO
C5G-----COPY FLOW TO DRAI.
   99 CONTINUE
      IF(IBD.EQ.2)THEN 
        CALL UBDSVREC(IUNSTR,N,NODES,NNCLNNDS,IDRNCB,IICLNCB,NDRNVL,
     1    6,NAUX,Q,DRAI(:,L),IBOUND,NCOL,NROW,NLAY)
      ENDIF
      DRAI(NDRNVL,L)=QQ
  100 CONTINUE
C
C6------IF CELL-BY-CELL FLOW WILL BE SAVED AS A 3-D ARRAY,
C6------CALL UBUDSV TO SAVE THEM.
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.1) CALL UBUDSV(KSTP,KPER,TEXT,IDRNCB,BUFF(1),NCOL,
     1                          NROW,NLAY,IOUT)
      ELSE
        IF(IBD.EQ.1) CALL UBUDSVU(KSTP,KPER,TEXT,IDRNCB,BUFF(1),NODES,
     1                          IOUT,PERTIM,TOTIM)
      ENDIF
      IF(IBD.EQ.1.AND.INCLN.GT.0)THEN
        IF(ICLNCB.GT.0) CALL UBUDSVU(KSTP,KPER,TEXT,ICLNCB,
     1    BUFF(NODES+1),NCLNNDS,IOUT,PERTIM,TOTIM)
      ENDIF
C
C7------MOVE RATES,VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 ROUT=RATOUT
      VBVL(3,MSUM)=ZERO
      VBVL(4,MSUM)=ROUT
      VBVL(2,MSUM)=VBVL(2,MSUM)+ROUT*DELT
      VBNM(MSUM)=TEXT
C
C8------INCREMENT BUDGET TERM COUNTER.
      MSUM=MSUM+1
C
C9------RETURN.
      RETURN
      END
      SUBROUTINE GWF2DRN7U1DA
C  Deallocate DRN MEMORY
      USE GWFDRNMODULE
C
        DEALLOCATE(NDRAIN)
        DEALLOCATE(MXDRN)
        DEALLOCATE(NDRNVL)
        DEALLOCATE(IDRNCB)
        DEALLOCATE(IPRDRN)
        DEALLOCATE(NPDRN)
        DEALLOCATE(IDRNPB)
        DEALLOCATE(NNPDRN)
        DEALLOCATE(DRNAUX)
        DEALLOCATE(DRAI)
C
      RETURN
      END
