//  PipeTrace.m
//  GMMobile

#import "PipeTrace.h"


typedef struct {int SEQUENCE;
    char NXTFID[14];
    char UPPIPE[14];
    char DN_NODE[14];
} NEXTPIPEdn;

typedef struct {int SEQUENCE;
    char NXTFID[14];
    char DNPIPE[14];
    char UP_NODE[14];
} NEXTPIPEup;

typedef struct {
    char FACILITY_ID[14];
    char DOWN_NODE[14];
    char UP_NODE[14];
} PIPEDB;

typedef struct {
    char FID[14];
    char UPPIPE[14];
    int  SQ;
    int  NFOUND;
} PIPETRACEDB;

@interface PipeTrace ()

@property (nonatomic) SewerData *sd;

@end

@implementation PipeTrace

+ (void)removeTrace
{
    SewerData *sd = [[SewerData alloc] init];
    [sd open];
    [sd executeCmd:"DROP TABLE IF EXISTS TRACE_HIGHLIGHT;"];
    [sd close];
}

- (int)getPipeTraceBounds
{
    return 0;
}

- (BOOL)havePipeTrace
{
    BOOL rtn = [self getPipeTraceCount] > 0;
    
    return rtn;
}

- (BOOL)getUpDownNodes:(LPSTR)atFid
                    up:(LPSTR)upNode
                    dn:(LPSTR)dnNode
{
    BOOL rtn = NO;
    sqlite3_stmt *statement = NULL;
    NSString * query = [NSString stringWithFormat:@"SELECT UP_NODE,DOWN_NODE FROM STORM_MAIN WHERE FACILITY_ID = '%s'",atFid];
    
    SQLOK(0,sqlite3_prepare_v2(_sd.database, query.UTF8String, -1, &statement, 0), _sd.database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        strcpy (upNode,(LPSTR)sqlite3_column_text(statement, 0));
        strcpy (dnNode,(LPSTR)sqlite3_column_text(statement, 1));
        rtn = TRUE;
    }
    
    SQLOK(0,sqlite3_finalize(statement), _sd.database);
    return rtn;
}

-(BOOL) $FETCH_NEXTPIPEdn:(NEXTPIPEdn *)np
{
    BOOL rtn = FALSE;
    NSString *query;
    sqlite3_stmt *statement = NULL;
    
    query = @"SELECT SEQUENCE,NXTFID,UPPIPE,DN_NODE FROM NEXTPIPE WHERE SEQUENCE >= 0 LIMIT 1";
    
    SQLOK(0,sqlite3_prepare_v2(_sd.database, query.UTF8String, -1, &statement, 0),_sd.database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        np->SEQUENCE = sqlite3_column_int(statement,0);
        strcpy (np->NXTFID,(LPSTR)sqlite3_column_text(statement,1));
        strcpy (np->UPPIPE,(LPSTR)sqlite3_column_text(statement,2));
        strcpy (np->DN_NODE,(LPSTR)sqlite3_column_text(statement,3));
        rtn = TRUE;
    }
    
    SQLOK(0,sqlite3_finalize(statement), _sd.database);
    return rtn;
}
-(BOOL) $FETCH_NEXTPIPEup:(NEXTPIPEup *)np
{
    BOOL rtn = FALSE;
    NSString *query;
    sqlite3_stmt *statement = NULL;
    
    query = @"SELECT SEQUENCE,NXTFID,DOWNPIPE,UP_NODE FROM NEXTPIPE WHERE SEQUENCE >= 0 LIMIT 1";
    
    SQLOK(0,sqlite3_prepare_v2(_sd.database, query.UTF8String, -1, &statement, 0),_sd.database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        np->SEQUENCE = sqlite3_column_int(statement,0);
        strcpy (np->NXTFID,(LPSTR)sqlite3_column_text(statement,1));
        strcpy (np->DNPIPE,(LPSTR)sqlite3_column_text(statement,2));
        strcpy (np->UP_NODE,(LPSTR)sqlite3_column_text(statement,3));
        rtn = TRUE;
    }
    
    SQLOK(0,sqlite3_finalize(statement), _sd.database);
    return rtn;
}
-(BOOL) $FETCH_PIPEDB_BYFID:(LPSTR)fid returns:(PIPEDB *)pdb
{
    BOOL rtn = FALSE;
    NSString *query;
    sqlite3_stmt *statement = NULL;
    /*CREATE TABLE STORM_MAIN ('FACILITY_ID' CHAR(12),'OBJECTID' INT,'Shape' CHAR(64),'Enabled' INT,'YEAR_BUILT' INT,'STATUS' CHAR(20),'DOCUMENT_LINK' CHAR(250),'BUILT_BY' CHAR(32),'DATA_SOURCE' CHAR(70),'DATA_SOURCE_TYPE' CHAR(16),'SOURCE_USED' CHAR(200),'OWNER' CHAR(60),'MAINTAINED_BY' CHAR(40),'CREATED_BY' CHAR(20),'CREATED_DATE' INT,'LAST_MODIFIED_BY' CHAR(20),'SUBTYPE_CODE' INT,'COMMON_NAME' CHAR(32),'MATERIAL' CHAR(60),'SOURCE_LENGTH_FT' REAL,'MANNINGS_N' REAL,'LINED' CHAR(3),'CAST_IN_PLACE' CHAR(3),'INVERT_IN_ELEV' REAL,'INVERT_OUT_ELEV' REAL,'DIAMETER_IN' REAL,'EQUIVALENT_DIAMETER_IN' REAL,'WIDTH_IN' REAL,'HEIGHT_IN' REAL,'HEIGHT_FT' REAL,'PLAT' CHAR(64),'PIPE_SHAPE' CHAR(30),'UP_NODE' CHAR(12),'DOWN_NODE' CHAR(12),'COMMENTS' CHAR(250),'CONFIDENCE' CHAR(1),'LOCATOR_NAME' CHAR(12),'GlobalID' CHAR(38),'PACP_SHAPE' CHAR(1),'PACP_HEIGHT' REAL,'PACP_CITY' CHAR(10),'PACP_LOCATION' CHAR(64),'YEAR_LINED' INT,'LAST_MODIFIED_DATE' INT,'UDI' CHAR(12),'MODELING_PIPE_SHAPE' INT,'MODELING_PIPE_SHAPE_INDEX' INT,'PACP_YEAR_BUILT' INT,'PACP_MATERIAL' CHAR(5),'Shape_STLength__' REAL,'Shape_STLength_1' REAL,'Shape_Length' REAL,PRIMARY KEY('FACILITY_ID' ASC))*/
    
    query = [NSString stringWithFormat:@"SELECT UP_NODE,DOWN_NODE FROM STORM_MAIN WHERE FACILITY_ID = %s",fid];
    
    SQLOK(0,sqlite3_prepare_v2(_sd.database, query.UTF8String, -1, &statement, 0), _sd.database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        strcpy (pdb->UP_NODE,(LPSTR)sqlite3_column_text(statement,0));
        strcpy (pdb->DOWN_NODE,(LPSTR)sqlite3_column_text(statement,1));
        strcpy (pdb->FACILITY_ID,fid);
        rtn = TRUE;
    }
    
    SQLOK(0,sqlite3_finalize(statement), _sd.database);
    return rtn;
}
-(BOOL) $FETCH_PIPEDB_BYUPN:(LPSTR)UPNODE returns:(PIPEDB *)pdb
{
    NSString *query;
    static sqlite3_stmt *statement = NULL;
    
    if (UPNODE)
    {
        query = [NSString stringWithFormat:@"SELECT FACILITY_ID,DOWN_NODE,UP_NODE FROM STORM_MAIN WHERE UP_NODE = %s",UPNODE];
        
        SQLOK(0,sqlite3_prepare_v2(_sd.database, query.UTF8String, -1, &statement, 0),_sd.database);
    }
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        strcpy (pdb->FACILITY_ID,(LPSTR)sqlite3_column_text(statement,0));
        strcpy (pdb->DOWN_NODE,(LPSTR)sqlite3_column_text(statement,1));
        strcpy (pdb->UP_NODE,(LPSTR)sqlite3_column_text(statement,2));
        return TRUE;
    }
    
    SQLOK(0,sqlite3_finalize(statement), _sd.database);
    return FALSE;
}
-(BOOL) $FETCH_PIPEDB_BYDNN:(LPSTR)DNNODE returns:(PIPEDB *)pdb
{
    NSString *query;
    static sqlite3_stmt *statement = NULL;
    
    if (DNNODE)
    {
        query = [NSString stringWithFormat:@"SELECT FACILITY_ID,DOWN_NODE,UP_NODE FROM STORM_MAIN WHERE DOWN_NODE = %s",DNNODE];
        
        SQLOK(0,sqlite3_prepare_v2(_sd.database, query.UTF8String, -1, &statement, 0), _sd.database);
    }
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        strcpy (pdb->FACILITY_ID,(LPSTR)sqlite3_column_text(statement,0));
        strcpy (pdb->DOWN_NODE,(LPSTR)sqlite3_column_text(statement,1));
        strcpy (pdb->UP_NODE,(LPSTR)sqlite3_column_text(statement,2));
        return TRUE;
    }
    
    SQLOK(0,sqlite3_finalize(statement),_sd.database);
    return FALSE;
}
-(BOOL)$FETCH_FOUND:(LPSTR)fid returns:(PIPETRACEDB*)ptdb
{
    BOOL rtn = FALSE;
    NSString *query;
    sqlite3_stmt *statement = NULL;
    
    query = [NSString stringWithFormat:@"SELECT UPPIPE,SQ FROM PIPETRACEDB WHERE FEATURE_ID = %s",fid];
    
    SQLOK(0,sqlite3_prepare_v2(_sd.database, query.UTF8String, -1, &statement, 0), _sd.database);
    
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        strcpy (ptdb->UPPIPE,(LPSTR)sqlite3_column_text(statement,0));
        ptdb->SQ = sqlite3_column_int(statement,1);
        strcpy (ptdb->FID,fid);
        rtn = TRUE;
    }
    
    SQLOK(0,sqlite3_finalize(statement),_sd.database);
  
    return rtn;
}
-(void)INSERT_FOUND:(PIPETRACEDB*)ptdb
{
    char cmd[256];
    
    sprintf (cmd,"INSERT INTO PIPETRACEDB VALUES('%s','%s',%i,%i)",ptdb->FID,ptdb->UPPIPE,ptdb->SQ,ptdb->NFOUND);
    [_sd executeCmd:cmd];
}
-(void)INSERT_HIGHLIGHT:(LPSTR)fid insertSequence:(int)seq
{
    char cmd[256];
    
    sprintf (cmd,"INSERT INTO TRACE_HIGHLIGHT VALUES('%s',%i)",fid,seq);
    [_sd executeCmd:cmd];
}
-(void) $DELETE_NEXTPIPE:(int)ATSEQ
{
    char cmd[256];
    
    sprintf (cmd,"DELETE FROM NEXTPIPE WHERE SEQUENCE = %i",ATSEQ);
    
    [_sd executeCmd:cmd];
}

LPSTR $TRUNCATE(LPSTR text)
{
    LPSTR pLoc = strchr (text,0);
    while (pLoc != text && *pLoc == ' ')
        pLoc--;
    *pLoc = 0;
    return text;
}
- (void)tracePipeDownstream:(NSString *)fromFacilityID
{
    char cmd[512];
    char UPNODE[16], DNNODE[16], PIPEFID[16], LASTFID[16];
    NEXTPIPEdn NEXTPIPE;
    PIPEDB PIPEDB, PIPEDB_BYUPN;
    PIPETRACEDB PIPETRACEDB;
    int ATSEQ, SEQ=1, insertSequence=0;
    
    _sd = [[SewerData alloc]init];
    
    [_sd open];
    
    if ([self getUpDownNodes:(LPSTR)fromFacilityID.UTF8String
                          up:UPNODE
                          dn:DNNODE])
    {
        [_sd executeCmd:"CREATE TEMP TABLE NEXTPIPE (SEQUENCE INT PRIMARY KEY,NXTFID CHAR(12),UPPIPE CHAR(12),DN_NODE CHAR(12));"];
        [_sd executeCmd:"DROP TABLE IF EXISTS TRACE_HIGHLIGHT;CREATE TABLE TRACE_HIGHLIGHT (FACILITY_ID CHAR(12) PRIMARY KEY, INSERT_SEQUENCE INT);"];
        
        sprintf (cmd,"INSERT INTO NEXTPIPE VALUES(1,'%s','%s','%s');",
                 fromFacilityID.UTF8String, "", DNNODE);
        
        [_sd executeCmd:cmd];
        [_sd executeCmd:"CREATE TEMP TABLE PIPETRACEDB (FEATURE_ID CHAR(12) PRIMARY KEY,UPPIPE CHAR(12),SQ INT,NFOUND INT);"];
        
        int NPIPES = 0;
        while ([self $FETCH_NEXTPIPEdn:&NEXTPIPE])
        {
            ATSEQ=NEXTPIPE.SEQUENCE;
            
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               NSString * title = [NSString stringWithFormat:@"%i Pipes Traced",NPIPES];
                               _popover.title = title;
                           });
            strcpy (PIPEFID,NEXTPIPE.NXTFID);
            if(*$TRUNCATE(PIPEFID))
            {
                if([self $FETCH_PIPEDB_BYFID:PIPEFID returns:&PIPEDB])
                {
                    if (![self $FETCH_FOUND:PIPEFID returns:&PIPETRACEDB])
                    {
                        strcpy (PIPETRACEDB.FID,PIPEFID);
                        PIPETRACEDB.SQ = SEQ;
                        PIPETRACEDB.NFOUND = 1;
                        strcpy (PIPETRACEDB.UPPIPE,NEXTPIPE.UPPIPE);
                        NPIPES++;
                        [self INSERT_FOUND:&PIPETRACEDB];
                        [self INSERT_HIGHLIGHT:PIPETRACEDB.FID insertSequence:insertSequence++];
                        strcpy (UPNODE,PIPEDB.DOWN_NODE);
                        strcpy (LASTFID,PIPEDB.FACILITY_ID);
                        if(*$TRUNCATE(UPNODE))
                        {
                            LPSTR pUPNODE = UPNODE;
                            while([self $FETCH_PIPEDB_BYUPN:pUPNODE returns:&PIPEDB_BYUPN])
                            {
                                pUPNODE = 0;
                                SEQ++;
                                sprintf (cmd,"INSERT INTO NEXTPIPE VALUES(%i,'%s','%s','%s');",
                                        SEQ,PIPEDB_BYUPN.FACILITY_ID, LASTFID,PIPEDB_BYUPN.UP_NODE);
                                [_sd executeCmd:cmd];

                               // $GMDUPDATE(NEXTPIPE,SEQUENCE=[SEQ],NXTFID=[PIPEDB_BYUPN.FACILITY_ID];UPPIPE=[LASTFID];DISTFROMSTART=$FLT([UPDIST]+[PIPEDB_BYUPN.SOURCE_LENGTH_FT]);PIPESIZE=[PIPEDB_BYUPN.DIAMETER_IN];PIPELENGTH=[PIPEDB_BYUPN.SOURCE_LENGTH_FT];FID=[PIPEDB_BYUPN.FACILITY_ID];UP_NODE=[PIPEDB_BYUPN.UP_NODE]);
                            }
                        }
                    }
                    else
                    {
                        //[NF]=$INT([FOUND.NFOUND]+1);
                        PIPETRACEDB.NFOUND++;
                        sprintf (cmd,"UPDATE PIPETRACEDB SET NFOUND = %i WHERE FEATURE_ID = %s",PIPETRACEDB.NFOUND,PIPEFID);
                        [_sd executeCmd:cmd];
                       //$GMDUPDATE(FOUND,FID=[PIPEFID],NFOUND=[NF]);
                    }
                }
            }
            [self $DELETE_NEXTPIPE:ATSEQ];
        }
    }
    
    [_sd close];
    //int n = [self getPipeTraceCount];
    MNMXCORD bounds;
    [self getPipeTraceBounds:&bounds];
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [_popover hide];
                       if (self.delegate)
                           [self.delegate zoomToPipeTraceBounds:bounds];
                   });

    return;
}

- (void)tracePipeUpstream:(NSString *)fromFacilityID
{
    char cmd[512];
    char UPNODE[16], DNNODE[16], PIPEFID[16], LASTFID[16];
    NEXTPIPEup NEXTPIPE;
    PIPEDB PIPEDB, PIPEDB_BYDNN;
    PIPETRACEDB PIPETRACEDB;
    int ATSEQ, SEQ=1, insertSequence=0;
    
    _processingID = 1;
    _popover.delegate = self;
    _sd = [[SewerData alloc]init];
    
    [_sd open];
    
    if ([self getUpDownNodes:(LPSTR)fromFacilityID.UTF8String
                          up:UPNODE
                          dn:DNNODE])
    {
        [_sd executeCmd:"CREATE TEMP TABLE NEXTPIPE (SEQUENCE INT PRIMARY KEY,NXTFID CHAR(12),DOWNPIPE CHAR(12),UP_NODE CHAR(12));"];
        [_sd executeCmd:"DROP TABLE IF EXISTS TRACE_HIGHLIGHT;CREATE TABLE TRACE_HIGHLIGHT (FACILITY_ID CHAR(12) PRIMARY KEY, INSERT_SEQUENCE INT);"];
        
        sprintf (cmd,"INSERT INTO NEXTPIPE VALUES(1,'%s','%s','%s');",
                 fromFacilityID.UTF8String, "",UPNODE);
        
        [_sd executeCmd:cmd];
        [_sd executeCmd:"CREATE TEMP TABLE PIPETRACEDB (FEATURE_ID CHAR(12) PRIMARY KEY,UPPIPE CHAR(12),SQ INT,NFOUND INT);"];
        
        int NPIPES = 0;
        while (_processingID && [self $FETCH_NEXTPIPEup:&NEXTPIPE])
        {
            ATSEQ=NEXTPIPE.SEQUENCE;
            
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               NSString * title = [NSString stringWithFormat:@"%i Pipes Traced",NPIPES];
                               _popover.title = title;
                           });
            strcpy (PIPEFID,NEXTPIPE.NXTFID);
            if(*$TRUNCATE(PIPEFID))
            {
                if([self $FETCH_PIPEDB_BYFID:PIPEFID returns:&PIPEDB])
                {
                    if (![self $FETCH_FOUND:PIPEFID returns:&PIPETRACEDB])
                    {
                        strcpy (PIPETRACEDB.FID,PIPEFID);
                        PIPETRACEDB.SQ = SEQ;
                        PIPETRACEDB.NFOUND = 1;;
                        strcpy (PIPETRACEDB.UPPIPE,NEXTPIPE.DNPIPE);
                        NPIPES++;
                        [self INSERT_FOUND:&PIPETRACEDB];
                        [self INSERT_HIGHLIGHT:PIPETRACEDB.FID insertSequence:insertSequence++];
                        strcpy (DNNODE,PIPEDB.UP_NODE);
                        strcpy (LASTFID,PIPEDB.FACILITY_ID);
                        if(*$TRUNCATE(DNNODE))
                        {
                            LPSTR pDNNODE = DNNODE;
                            while([self $FETCH_PIPEDB_BYDNN:pDNNODE returns:&PIPEDB_BYDNN])
                            {
                                pDNNODE = 0;
                                SEQ++;
                                sprintf (cmd,"INSERT INTO NEXTPIPE VALUES(%i,'%s','%s','%s');",
                                         SEQ,PIPEDB_BYDNN.FACILITY_ID, LASTFID,PIPEDB_BYDNN.UP_NODE);
                                [_sd executeCmd:cmd];
                            }
                        }
                    }
                    else
                    {
                        PIPETRACEDB.NFOUND++;
                        sprintf (cmd,"UPDATE PIPETRACEDB SET NFOUND = %i WHERE FEATURE_ID = %s",PIPETRACEDB.NFOUND,PIPEFID);
                        [_sd executeCmd:cmd];
                    }
                }
            }
            [self $DELETE_NEXTPIPE:ATSEQ];
        }
    }
    
    [_sd close];
    //int n = [self getPipeTraceCount];
    
    if (_processingID)
    {
        MNMXCORD bounds;
        [self getPipeTraceBounds:&bounds];
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [_popover hide];
                           
                           if (self.delegate)
                               [self.delegate zoomToPipeTraceBounds:bounds];
                       });
    }
    
    else
    {
        [_sd open];
        [_sd executeCmd:"DROP TABLE TRACE_HIGHLIGHT;"];
        [_sd close];
    }
    
    return;
}

- (void) GSSiPopoverViewdidCancel:(GSSiPopoverView *)popoverView
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [_popover hide];
                   });
    _processingID = 0;
}
/*
[PIPEDB]=$SYMATTRFILE(#[%ARG(1)]);
[ATTRLOC]=LOCAL;[%AUTOPAN]=F;
[NXTFILE]=$GETTEMPFILE(gm,gmd);[SEQ]=1;
$OPEN(PIPEDB=[PIPEDB],FACILITY_ID=[%ARG(2)]);
IF($FETCH(PIPEDB)){[ATFID]=[PIPEDB.FACILITY_ID];}ELSE{$CLOSE(PIPEDB);$MESSAGE(Pipe not found);$RETURN(0);};
$GMDCREATE([NXTFILE],1,(SEQUENCE(B4),NXTFID(C12),DOWNPIPE(C12),FID(C12),DISTFROMSTART(R8),PIPESIZE(R8),PIPELENGTH(R8),UP_NODE(C12)));
$GMDUPDATE([NXTFILE],SEQUENCE=1,NXTFID=[ATFID];DISTFROMSTART=0;DOWNPIPE=;PIPESIZE=[PIPEDB.DIAMETER_IN];PIPELENGTH=[PIPEDB.SOURCE_LENGTH_FT];FID=[PIPEDB.FACILITY_ID]);
$CLOSE(PIPEDB);
$HLT(CLEAR);
IF([CREATEPIDLIST])
{
    [PIDFILE]=$GETTEMPFILE(gm,gmd);
    $GMDCREATE([PIDFILE],1,(PIDNO(C13),HOUSE(C10),STREET(C80)));
};
$OPEN(NEXTPIPE=[NXTFILE],SEQUENCE>@[SEARCHSEQ],W);
[REVFILE]=$GETTEMPFILE(gm,gmd);
$GMDCREATE([REVFILE],1,(REVSEQUENCE(B4),REVFID(C12),DOWNPIPE(C12),FID(C12),DISTFROMSTART(R8),PIPESIZE(R8),PIPELENGTH(R8),UP_NODE(C12)));
$GMDCREATE([PIPETRACEDB],1,(FID(C12),DOWNPIPE(C12),DISTFROMSTART(R8),CONTHISPIPE(B4),TOTCON(B4),PIPESIZE(R8),PIPELENGTH(R8),SQ(B4),NFOUND(B4)));
$OPEN(REVERSE=[REVFILE],,W);
$OPEN(PIPEDB_BYFID=[PIPEDB],FACILITY_ID=@[PIPFID]);
$OPEN(PIPEDB_BYDNN=[PIPEDB],DOWN_NODE=@[PIPDNN]);
$OPEN(FOUND=[PIPETRACEDB],FID=@[PIPEFID],W);
[SEARCHSEQ]=0;[NPIPES]=0;
$STATUS(CREATE,Searching upstream);
WHILE($STATUS(UPDATE,0,0,[NPIPES] pipes found)&&$FETCH(NEXTPIPE))
{$B(2)
    [ATSEQ]=[NEXTPIPE.SEQUENCE];
    $GMDUPDATE(REVERSE,REVSEQUENCE=-[ATSEQ],REVFID=[NEXTPIPE.NXTFID];DOWNPIPE=[NEXTPIPE.DOWNPIPE];DISTFROMSTART=[NEXTPIPE.DISTFROMSTART];PIPESIZE=[NEXTPIPE.PIPESIZE];PIPELENGTH=[NEXTPIPE.PIPELENGTH];FID=[NEXTPIPE.FID];UP_NODE=[NEXTPIPE.UP_NODE]);
    [PIPFID]=[NEXTPIPE.NXTFID];
    IF($TRUNCATE([PIPFID])!='')
    {
        IF($FETCH(PIPEDB_BYFID))
        {$B(3)
            [PIPEFID]=[PIPEDB_BYFID.FACILITY_ID];
            IF(!$FETCH(FOUND))
            {
                $GMDUPDATE(FOUND,FID=[PIPEFID],SQ=[SEQ];NFOUND=1;DISTFROMSTART=[NEXTPIPE.DISTFROMSTART];DOWNPIPE=[NEXTPIPE.DOWNPIPE];PIPESIZE=[NEXTPIPE.PIPESIZE];PIPELENGTH=[NEXTPIPE.PIPELENGTH]);$INC(NPIPES);
                IF([HIGHLIGHT]){IF($HLT(ITEM,FACILID:[PIPEDB_BYFID.FACILITY_ID],F,Primary Viewport,T)!=1){$MESSAGEx([PIPEDB_BYFID.FACILITY_ID]);};};
                [UPFID]=[PIPEDB_BYFID.UP_NODE];
                [LASTFID]=[PIPEDB_BYFID.FACILITY_ID];[LASTFID]=[PIPEDB_BYFID.FACILITY_ID];[DOWNDIST]=[NEXTPIPE.DISTFROMSTART];
                [PIPDNN]=[UPFID];$B(5)
                IF($TRUNCATE([PIPDNN])!='')
                {
                    WHILE($FETCH(PIPEDB_BYDNN))
                    {
                        $INC(SEQ);
                        $B(4)
                        $GMDUPDATE(NEXTPIPE,SEQUENCE=[SEQ],NXTFID=[PIPEDB_BYDNN.FACILITY_ID];DOWNPIPE=[LASTFID];DISTFROMSTART=$FLT([DOWNDIST]+[PIPEDB_BYDNN.SOURCE_LENGTH_FT]);PIPESIZE=[PIPEDB_BYDNN.DIAMETER_IN];PIPELENGTH=[PIPEDB_BYDNN.SOURCE_LENGTH_FT];FID=[PIPEDB_BYDNN.FACILITY_ID];UP_NODE=[PIPEDB_BYDNN.UP_NODE]);
                    };
                };
            }
            ELSE
            {
                [NF]=$INT([FOUND.NFOUND]+1);
                $GMDUPDATE(FOUND,FID=[PIPEFID],NFOUND=[NF]);
            };
        };
    };
    $GMDDELETE(NEXTPIPE,SEQUENCE=[ATSEQ]);
    [SEARCHSEQ]=0;
};
$STATUS(DESTROY);
$CLOSE(FOUND);
$CLOSE(PIPEDB_BYFID);
$CLOSE(PIPEDB_BYDNN);
$CLOSE(NEXTPIPE);
$DELETEFILE([NXTFILE]);
$CLOSE(REVERSE);
IF([CREATEPIDLIST])
{
    $OPEN(REVERSE=[REVFILE],REVSEQUENCE>@[REVSEQ],W);
    $OPEN(TRACEDB=[PIPETRACEDB],UDI=@[TRACEUDI],W);
    [REVSEQ]=-2000000001;
    WHILE($FETCH(REVERSE))
    {
        [ATSEQ]=[REVERSE.REVSEQUENCE];
        [%WT]=$FLT(0-[ATSEQ]);
        [TRACEUDI]=[REVERSE.REVUDI];
        [NUMCON]=$MACRO([%DL]macros\fixsewer\NumPipeConnections.txt,[TRACEUDI],[REVERSE.UP_NODE]);
        IF($FETCH(TRACEDB))
        {
            [TOTCON]=$FLT([TRACEDB.TOTCON]+[NUMCON]);
        }
        ELSE
        {
            [TOTCON]=[NUMCON];
        };
        $GMDUPDATE(TRACEDB,UDI=[TRACEUDI],
                   DOWNPIPE=[REVERSE.DOWNPIPE];
                   DISTFROMSTART=[REVERSE.DISTFROMSTART];
                   CONTHISPIPE=[NUMCON];
                   TOTCON=[.TOTCON];
                   PIPELENGTH=[REVERSE.PIPELENGTH];
                   PIPESIZE=[REVERSE.PIPESIZE];
                   FACILITY_ID=[REVERSE.FID]);
        [TRACEUDI]=[REVERSE.DOWNPIPE];
        IF($FETCH(TRACEDB))
        {
            [DOWNCON]=$FLT([TRACEDB.TOTCON]+[.TOTCON]);
        }
        ELSE
        {
            [DOWNCON]=[.TOTCON];
        };
        $GMDUPDATE(TRACEDB,UDI=[TRACEUDI],TOTCON=[DOWNCON]);
        $GMDDELETE(REVERSE,REVSEQUENCE=[ATSEQ]);
        [REVSEQ]=-2000000001;
    };
    $CLOSE(REVERSE);
    $DELETEFILE([REVFILE]);
    $CLOSE(TRACEDB);
};
$GMDADDINDEX([PIPETRACEDB],FACILITY_ID,T);
$VIS(AUTO,1);
IF([CREATEPIDLIST])
{
    $REPORT([%DL]reports\pidlist.txt,SCROLL);
    $DELETEFILE([PIDFILE]);
};
IF($BOUNDS(INBOUNDS,[%HLTBOUNDS],[%VPBOUNDS]))
{
    $REDISPLAY(T);
}
ELSE
{
    $ZOOM(BOUNDS,$BOUNDS(FACTOR,[%HLTBOUNDS],1.1));
};
$HLTx(CLEAR);
$MESSAGEx([NPIPES] total pipes found);
$RETURN(1);
*/
-(void) getPipeTraceBounds:(MNMXCORD*)pbounds
{
    DPOINT BasePt, point;
    int numPoints;
    sqlite3_stmt *statement = NULL;
    dbounds bounds;
    
    [CRAPI.sharedInstance logToErrorFileIgnore:YES];
    InitDBounds(&bounds);
    
    NSString * query = @"SELECT BasePointX,BasePointY,NumPoints,Points FROM TRACE_HIGHLIGHT,STORM_LINE WHERE STORM_LINE.FACILITY_ID = TRACE_HIGHLIGHT.FACILITY_ID";

    _sd = [[SewerData alloc]init];
    [_sd open];
    SQLOK(0,sqlite3_prepare_v2(_sd.database, query.UTF8String, -1, &statement, 0),_sd.database);

    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        BasePt.x = sqlite3_column_double(statement,0);
        BasePt.y = sqlite3_column_double(statement,1);
        numPoints = sqlite3_column_int(statement,2);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,3);
        
        if (numPoints < 0)
        {
            numPoints = -numPoints;
            LPSPOINT offsetPoints16 = (LPSPOINT)offsetPoints;
            
            for (int i = 0; i < numPoints; i++)
            {
                point.x = (BasePt.x + offsetPoints16[i].x / COORDINATE_FACTOR);
                point.y = (BasePt.y + offsetPoints16[i].y / COORDINATE_FACTOR);
                AddDPointToBounds(&bounds, &point);
            }
        }
        
        else for (int i = 0; i < numPoints; i++)
        {
            point.x = (BasePt.x + offsetPoints[i].x / COORDINATE_FACTOR);
            point.y = (BasePt.y + offsetPoints[i].y / COORDINATE_FACTOR);
            AddDPointToBounds(&bounds, &point);
        }
    }
    
    SQLOK(0,sqlite3_finalize(statement),_sd.database);
    *pbounds = bounds;
    [_sd close];
    [CRAPI.sharedInstance logToErrorFileIgnore:NO];

}

-(int) getPipeTraceCount
{
    int nrec = 0;
    sqlite3_stmt *statement = NULL;
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM TRACE_HIGHLIGHT;"];
    [CRAPI.sharedInstance logToErrorFileIgnore:YES];
    
    SewerData *sd = [[SewerData alloc]init];
    [sd open];
    SQLOK(0,sqlite3_prepare_v2(sd.database, query.UTF8String, -1, &statement, 0), sd.database);
    if (sqlite3_step(statement) == SQLITE_ROW)
    {
        nrec = sqlite3_column_int(statement,0);
    }
    
    SQLOK(0,sqlite3_finalize(statement),sd.database);
    [sd close];
    [CRAPI.sharedInstance logToErrorFileIgnore:NO];
    return nrec;
}

- (BOOL)continueProcessing
{
    if (!self.processingID)
        return YES;
    if (self.processingID == CRAPI.sharedInstance.keepProcessing)
        return YES;
    return NO;
}

- (void)displayPipeTrace:(CGContextRef)context
               llCorners:(CORNERPOINTS *)latlonCornerPoints
                LLBounds:(MNMXCORD *)platlonBounds
              viewBounds:(MNMXCORD *)pvbounds
{
    DPOINT BasePt;
    int numPoints;
    CGColorRef color = UIColor.redColor.CGColor;
    [CRAPI.sharedInstance logToErrorFileIgnore:YES];

    sqlite3_stmt *statement = NULL;
    NSString * query = @"SELECT BasePointX,BasePointY,NumPoints,Points FROM TRACE_HIGHLIGHT,STORM_LINE WHERE STORM_LINE.FACILITY_ID = TRACE_HIGHLIGHT.FACILITY_ID";
    
    _sd = [[SewerData alloc]init];
    [_sd open];
 
    [_sd setTrans:latlonCornerPoints
       viewBounds:pvbounds];
    
    SQLOK(0,sqlite3_prepare_v2(_sd.database, query.UTF8String, -1, &statement, 0),_sd.database);
    
    while ([self continueProcessing] && sqlite3_step(statement) == SQLITE_ROW)
    {
        BasePt.x = sqlite3_column_double(statement,0);
        BasePt.y = sqlite3_column_double(statement,1);
        numPoints = sqlite3_column_int(statement,2);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,3);
        LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
       
        if (numPoints < 0)
        {
            numPoints = -numPoints;
            LPSPOINT offsetPoints16 = (LPSPOINT)offsetPoints;
            
            for (int i = 0; i < numPoints; i++)
            {
                llpoints[i].x = (BasePt.x + offsetPoints16[i].x / COORDINATE_FACTOR);
                llpoints[i].y = (BasePt.y + offsetPoints16[i].y / COORDINATE_FACTOR);
                llpoints[i] = TranDPOINT(&llpoints[i], _sd.pTranLLtoView);
            }
        }
        
        else for (int i = 0; i < numPoints; i++)
        {
            llpoints[i].x = (BasePt.x + offsetPoints[i].x / COORDINATE_FACTOR);
            llpoints[i].y = (BasePt.y + offsetPoints[i].y / COORDINATE_FACTOR);
            llpoints[i] = TranDPOINT(&llpoints[i], _sd.pTranLLtoView);
        }
        
        [_sd drawStormLine:context
                       pass:LINE_PASS
                    nPoints:numPoints
                     points:llpoints
                  withColor:color
                   andWidth:15
                    andText:nil
                andPointers:YES];
        
        free(llpoints);
    }
    
    SQLOK(0,sqlite3_finalize(statement), _sd.database);
    [_sd close];
    [CRAPI.sharedInstance logToErrorFileIgnore:NO];
}

- (BOOL)outputPipeTrace:(NSString *)toPath
{
    BOOL rtn = FALSE;
    DPOINT BasePt;
    int numPoints;
    LPDPOINT outputArray = nil;
    int numOutputPoints = 0;
    
    sqlite3_stmt *statement = NULL;
    NSString *query = @"SELECT BasePointX,BasePointY,NumPoints,Points FROM TRACE_HIGHLIGHT,STORM_LINE WHERE STORM_LINE.FACILITY_ID = TRACE_HIGHLIGHT.FACILITY_ID";
    
    _sd = [[SewerData alloc] init];
    [_sd open];
    
    SQLOK(0,sqlite3_prepare_v2(_sd.database, query.UTF8String, -1, &statement, 0),_sd.database);
    
    while (sqlite3_step(statement) == SQLITE_ROW)
    {
        BasePt.x = sqlite3_column_double(statement,0);
        BasePt.y = sqlite3_column_double(statement,1);
        numPoints = sqlite3_column_int(statement,2);
        LPIPOINT offsetPoints = (LPIPOINT)sqlite3_column_blob(statement,3);
        LPDPOINT llpoints = malloc(abs(numPoints) * sizeof(DPOINT) + 4);
        
        if (numPoints < 0)
        {
            numPoints = -numPoints;
            LPSPOINT offsetPoints16 = (LPSPOINT)offsetPoints;
            
            for (int i = 0; i < numPoints; i++)
            {
                llpoints[i].x = (BasePt.x + offsetPoints16[i].x / COORDINATE_FACTOR);
                llpoints[i].y = (BasePt.y + offsetPoints16[i].y / COORDINATE_FACTOR);
            }
        }
        
        else for (int i = 0; i < numPoints; i++)
        {
            llpoints[i].x = (BasePt.x + offsetPoints[i].x / COORDINATE_FACTOR);
            llpoints[i].y = (BasePt.y + offsetPoints[i].y / COORDINATE_FACTOR);
        }
        
        if (outputArray == nil)
        {
            outputArray = malloc (numPoints * sizeof(DPOINT)+4);
            numOutputPoints = numPoints;
        }
        
        else
        {
            int np = numPoints;
            LPDPOINT pdp = llpoints;
            
            if (sameDPoint(&outputArray[numOutputPoints - 1], &llpoints[0], 0.00000001))
            {
                np--;
                pdp++;
            }
            if (np > 0)
            {
                outputArray = realloc(outputArray,(numOutputPoints + np) * sizeof(DPOINT)+4);
                memmove(&outputArray[numOutputPoints], pdp, np * sizeof(DPOINT));
                numOutputPoints += np;
            }
        }
        free (llpoints);
    }
    
    SQLOK(0,sqlite3_finalize(statement), _sd.database);
    [_sd close];
    
    if (numOutputPoints)
    {
        FILE *fid = fopen(toPath.UTF8String, "wb");
        
        if (fid)
        {
            fwrite(&numOutputPoints, sizeof(int), 1, fid);
            fwrite(outputArray, (numOutputPoints * sizeof(DPOINT)), 1, fid);
            fclose(fid);
            rtn = YES;
        }
        
    }
    if (outputArray)
        free (outputArray);
    
    return rtn;
}

/*
 [PIPEDB]=$SYMATTRFILE(#[%ARG(1)]);
 [ATTRLOC]=LOCAL;[%AUTOPAN]=F;
 [NXTFILE]=$GETTEMPFILE(gm,gmd);[SEQ]=1;
 $OPEN(PIPEDB=[PIPEDB],FACILITY_ID=[%ARG(2)]);
 IF($FETCH(PIPEDB)){[ATFID]=[PIPEDB.FACILITY_ID];}ELSE{$CLOSE(PIPEDB);$MESSAGE(Pipe not found);$RETURN(0);};
 $GMDCREATE([NXTFILE],1,(SEQUENCE(B4),NXTFID(C12),UPPIPE(C12),FID(C12),DISTFROMSTART(R8),PIPESIZE(R8),PIPELENGTH(R8),DN_NODE(C12)));
 $GMDUPDATE([NXTFILE],SEQUENCE=1,NXTFID=[ATFID];DISTFROMSTART=0;UPPIPE=0;PIPESIZE=[PIPEDB.DIAMETER_IN];PIPELENGTH=[PIPEDB.SOURCE_LENGTH_FT];FID=[ATFID]);
 $CLOSE(PIPEDB);
 $HLT(CLEAR);
 $OPEN(NEXTPIPE=[NXTFILE],SEQUENCE>@[SEARCHSEQ],W);
 [REVFILE]=$GETTEMPFILE(gm,gmd);
 $GMDCREATE([REVFILE],1,(REVSEQUENCE(B4),REVFID(C12),UPPIPE(C12),FID(C12),DISTFROMSTART(R8),PIPESIZE(R8),PIPELENGTH(R8),DN_NODE(C12)));
 $GMDCREATE([PIPETRACEDB],1,(FID(C12),UPPIPE(C12),DISTFROMSTART(R8),CONTHISPIPE(B4),TOTCON(B4),PIPESIZE(R8),PIPELENGTH(R8),SQ(B4),NFOUND(B4)));
 $OPEN(REVERSE=[REVFILE],,W);
 $OPEN(PIPEDB_BYFID=[PIPEDB],FACILITY_ID=@[PIPFID]);
 $OPEN(PIPEDB_BYUPN=[PIPEDB],UP_NODE=@[PIPUPN]);
 $OPEN(FOUND=[PIPETRACEDB],FID=@[PIPEFID],W);
 [SEARCHSEQ]=0;[NPIPES]=0;
 $STATUS(CREATE,Searching downstream);
 WHILE($STATUS(UPDATE,0,0,[NPIPES] pipes found)&&$FETCH(NEXTPIPE))
 {
 [ATSEQ]=[NEXTPIPE.SEQUENCE];
 $GMDUPDATE(REVERSE,REVSEQUENCE=-[ATSEQ],REVFID=[NEXTPIPE.NXTFID];UPPIPE=[NEXTPIPE.UPPIPE];DISTFROMSTART=[NEXTPIPE.DISTFROMSTART];PIPESIZE=[NEXTPIPE.PIPESIZE];PIPELENGTH=[NEXTPIPE.PIPELENGTH];FID=[NEXTPIPE.FID];DN_NODE=[NEXTPIPE.DN_NODE]);
 [%WTx]=[ATSEQ];
 [PIPFID]=[NEXTPIPE.NXTFID];
 IF($TRUNCATE([PIPFID])!='')
 {
 IF($FETCH(PIPEDB_BYFID))
 {
 [PIPEFID]=[PIPEDB_BYFID.FACILITY_ID];
 IF(!$FETCH(FOUND))
 {
 $GMDUPDATE(FOUND,FID=[PIPEFID],SQ=[SEQ];NFOUND=1;DISTFROMSTART=[NEXTPIPE.DISTFROMSTART];UPPIPE=[NEXTPIPE.UPPIPE];PIPESIZE=[NEXTPIPE.PIPESIZE];PIPELENGTH=[NEXTPIPE.PIPELENGTH]);$INC(NPIPES);
 IF([HIGHLIGHT]){IF($HLT(ITEM,FACILID:[PIPEDB_BYFID.FACILITY_ID],F,Primary Viewport,T)!=1){$MESSAGEx([PIPEDB_BYFID.FACILITY_ID]);};};
 [UPFID]=[PIPEDB_BYFID.DOWN_NODE];
 [LASTFID]=[PIPEDB_BYFID.FACILITY_ID];[UPDIST]=[NEXTPIPE.DISTFROMSTART];
 [PIPUPN]=[UPFID];
 IF($TRUNCATE([PIPUPN])!='')
 {
 WHILE($FETCH(PIPEDB_BYUPN))
 {
 $INC(SEQ);
 $GMDUPDATE(NEXTPIPE,SEQUENCE=[SEQ],NXTFID=[PIPEDB_BYUPN.FACILITY_ID];UPPIPE=[LASTFID];DISTFROMSTART=$FLT([UPDIST]+[PIPEDB_BYUPN.SOURCE_LENGTH_FT]);PIPESIZE=[PIPEDB_BYUPN.DIAMETER_IN];PIPELENGTH=[PIPEDB_BYUPN.SOURCE_LENGTH_FT];FID=[PIPEDB_BYUPN.FACILITY_ID];UP_NODE=[PIPEDB_BYUPN.UP_NODE]);
 };
 };
 }
 ELSE
 {
 [NF]=$INT([FOUND.NFOUND]+1);
 $GMDUPDATE(FOUND,FID=[PIPEFID],NFOUND=[NF]);
 };
 };
 };
 $GMDDELETE(NEXTPIPE,SEQUENCE=[ATSEQ]);
 [SEARCHSEQ]=0;
 };
 $STATUS(DESTROY);
 $CLOSE(FOUND);
 $CLOSE(PIPEDB_BYFID);
 $CLOSE(PIPEDB_BYUPN);
 $CLOSE(NEXTPIPE);
 $DELETEFILE([NXTFILE]);
 $CLOSE(REVERSE);
 */

@end
