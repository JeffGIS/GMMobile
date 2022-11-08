//
//  ShapeFileDisplay.m
//  GMMobile
//
//  Created by JEFFREY E SMITH on 1/20/16.
//  Copyright © 2016 GSSi. All rights reserved.
//

#import "ShapeFileDisplay.h"

@interface ShapeFileDisplay ()

@property (nonatomic) LPTRANDATA pTranLLtoView, pTranViewtoLL;

@end

BOOL ShowTextInLoop (LPDPOINT llpoints, int npInLoop,LPMNMXCORD pvbounds)
{
    BOOL rtn = FALSE;
    MNMXCORD bounds;
    
    double area = ComputeAreaAreaD (llpoints,npInLoop,0,&bounds);
    rtn = BoundsInBounds (&bounds,pvbounds,1);
    if (rtn)
    {
        if (area < 0)
            rtn = FALSE;
    }
    return rtn;
}

@implementation ShapeFileDisplay

- (BOOL)continueProcessing
{
    if (!self.processingID)
        return YES;
    if (self.processingID == CRAPI.sharedInstance.keepProcessing)
        return YES;
    
    return NO;
}
- (id)init
{
    self = [super init];
    
    if (self)
    {
        _documentsDirectory = UserDefaults.defaults.sharedFilePath;
    }
    
    return self;
}

BOOL ReadNVP (LPCSTR file,LPSTR nvp)
{
    BOOL rtn = FALSE;
    NSString * shpFile = [NSString stringWithUTF8String:file];
    shpFile = [shpFile stringByDeletingPathExtension];
    shpFile = [shpFile stringByAppendingString:@".nvp"];
    NSString * contents = [NSString stringWithContentsOfFile:shpFile encoding:NSUTF8StringEncoding error:nil];
    if (contents.length)
    {
        rtn = TRUE;
        strcpy (nvp,contents.UTF8String);
    }
    return rtn;
}
BOOL ShapeFileIsLatLon(LPCSTR shapeFile)
{
    BOOL rtn = FALSE;
    NSString * nvpFile = [NSString stringWithUTF8String:shapeFile];
    nvpFile = [[nvpFile stringByDeletingPathExtension] stringByAppendingString:@".nvp"];
    NSString * contents = [NSString stringWithContentsOfFile:nvpFile encoding:NSUTF8StringEncoding error:nil];
    
    if ([contents containsString:@"longlat"])
        rtn = TRUE;
    return rtn;
}
+ (ShapeFileDisplay *)createWithFile:(const char*)shapeFile
{
    char outFile[MAX_PATH];
    SHPHandle hSHP;
    DBFHandle hDBF;
    ShapeFileDisplay * sfd = NULL;
    BOOL first = TRUE;
    
    if (!shapeFile)
        return NULL;
    
    sprintf (outFile,"%s",shapeFile);
    if (!ShapeFileIsLatLon(shapeFile))
    {
        char * pFS = strrchr (outFile,'/');
        if (pFS)
        {
            char * pFS2 = strrchr (shapeFile,'/');
            sprintf (pFS,"/latlong%s",pFS2);
        }
        else
            return NULL;
    }
    
Top:
/*    if (first)
        hSHP = NULL;
    else*/
    //[NSFileManager.defaultManager removeItemAtPath:[NSString stringWithUTF8String:outFile]
    //                                         error:nil];
        hSHP = SHPOpen( outFile, "rb" );
    if( hSHP != NULL )
    {
        hDBF = DBFOpen ( outFile, "rb" );
        if (hDBF == NULL)
        {
            SHPClose (hSHP);
            return NULL;
        }
        sfd = [[ShapeFileDisplay alloc]init];
        sfd.hSHP = hSHP;
        sfd.hDBF = hDBF;
        sfd.filePath = [NSString stringWithUTF8String:shapeFile];
        sfd.fileName = [sfd.filePath lastPathComponent];
    }
    else if (first)
    {
        first = FALSE;
        char * args[5];
        //char inprj_utm[] = {"-i=proj=utm zone=15 units=m datum=NAD83 no_defs" };//+proj=utm +zone=15 +datum=NAD83 +units=m +no_defs
        char inprj_utm[] = {"+proj=utm +zone=15 +datum=NAD83 +units=m +no_defs"};
        char inprj_hc[] = {"+proj=lcc +lat_1=45.13333333 +lat_2=44.88333333 +lat_0=44.79111111 +lon_0=-93.38333333 +x_0=152400.3048006096 +y_0=30480.06096012192 +a=6378418.941 +b=6357033.31 +units=us-ft +no_defs"};
        LPSTR nvp = malloc (4096);
        char outprj[] = "+proj=latlong +datum=WGS84";
        args[1] = (char *)shapeFile;
        args[2] = outFile;
        if (ReadNVP (shapeFile,nvp))
            args[3] = nvp;
        else
            args[3] = inprj_utm;
        if (strstr (shapeFile,"Fiber"))
            args[3] = inprj_hc;
        
        args[4] = outprj;
        [NSFileManager.defaultManager createDirectoryAtPath:[ [NSString stringWithUTF8String:outFile] stringByDeletingLastPathComponent]
                                withIntermediateDirectories:YES
                                                 attributes:nil
                                                      error:nil];
        if (TransformSHP (5,args))
        {
            free (nvp);
            goto Top;
        }
        free (nvp);
   }
   return sfd;
}
- (void)dealloc
{
    if (_hSHP)
        SHPClose(_hSHP);
    if (_hDBF)
        DBFClose(_hDBF);
}

-(void)  display:(CGContextRef)context
displayCharacteristics:(DisplayCharacteristics *)dc
       llCorners:(CORNERPOINTS *) latlonCornerPoints
        LLBounds:(MNMXCORD *)platlonBounds
      viewBounds:(MNMXCORD *)pvbounds
          themes:(Themes*)themes
     pointInArea:(PointInArea *)pia
{
    _dc = dc.copy;
    _dc.size = 1;
    _dc.width = 1;
    _sizeFactor = 25;

    if (_zoom > 18)
        _sizeFactor *= (2.0 *(_zoom - 18.0));
    else if (_zoom < 18)
        _sizeFactor /= (2.0 * (18.0 - _zoom));
    _widthFactor = _sizeFactor / 15;
    
    dc.string1 = _fileName;
    
    if ([_fileName containsString:@"Meter"])
    {
        dc.pointSymbol = Star2Sym;
        dc.fillColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:1];
        dc.penColor = [UIColor blackColor];
        _sizeFactor *=1.5;
    }
    CloseTRANS2P(&_pTranLLtoView);
    CloseTRANS2P(&_pTranViewtoLL);
    
    _pTranLLtoView = STRANCornersToBoundsP(latlonCornerPoints, pvbounds);
    [self processShape:context
         highlightList:nil
              LLBounds:platlonBounds
            viewBounds:pvbounds
                themes:themes];
    CloseTRANS2P(&_pTranLLtoView);
    CloseTRANS2P(&_pTranViewtoLL);
}
- (void)open
{
    if (!_isOpen)
    {
        
        _fileSize = (int)[NSFileManager.defaultManager attributesOfItemAtPath:_indexName
                                                                   error:nil].fileSize;
        _isOpen = !SQLOK(__FILE__,__LINE__,SQLite_Open(_indexName.UTF8String, &_database), _database);
        if (_fileSize <= 0)
        {
            [self startTransaction];
            
            NSString * cmd = @"CREATE VIRTUAL TABLE SHP_index USING rtree(id,minX, maxX, minY, maxY);CREATE TABLE SHP (id INT PRIMARY KEY);";
            [self executeCmd:cmd.UTF8String];
            for (int irec = 0; irec < _hSHP->nRecords; irec++)
            {
                SHPObject *psCShape = SHPReadObject (_hSHP, irec );
                MNMXCORD SHPBounds;
                SHPBounds.xmn = psCShape->dfXMin;
                SHPBounds.xmx = psCShape->dfXMax;
                SHPBounds.ymn = psCShape->dfYMin;
                SHPBounds.ymx = psCShape->dfYMax;
                cmd = [NSString stringWithFormat:@"INSERT INTO SHP_index VALUES(%i,%f,%f,%f,%f);INSERT INTO SHP VALUES(%i);",irec,SHPBounds.xmn,SHPBounds.xmx,SHPBounds.ymn,SHPBounds.ymx,irec];
                [self executeCmd:cmd.UTF8String];
                SHPDestroyObject ( psCShape );
            }

            [self commitTransaction];
        }
    }
}

- (void)close
{
    if (_isOpen)
    {
        SQLOK(__FILE__,__LINE__,SQLite_Close(&_database),_database);
        _isOpen = NO;
    }
}
- (BOOL)executeCmd:(LPCSTR)cmd
{
    BOOL rtn = !SQLOK(__FILE__,__LINE__,SQLiteExec(_database, cmd, 0, 0, 0), _database);
    return rtn;
}

- (void)startTransaction
{
    SQLOK(__FILE__,__LINE__,SQLiteExec(_database, "BEGIN", 0, 0, 0), _database);
}

- (void)commitTransaction
{
    SQLOK(__FILE__,__LINE__,SQLiteExec(_database, "COMMIT", 0, 0, 0),_database);
}

- (BOOL) openSLTIndex
{
    BOOL rtn = FALSE;
    _indexName = [_filePath stringByDeletingPathExtension];
    _indexName = [_indexName stringByAppendingString:@".slt"];
    [self open];
    rtn = TRUE;
    return rtn;
}
- (void)processShape:(CGContextRef)context
       highlightList:(NSMutableArray*)hlist
            LLBounds:(MNMXCORD *)platlonBounds
          viewBounds:(MNMXCORD *)pvbounds
              themes:(Themes*)themes
{
    double mind = DBL_MAX;
    DPOINT minpt, pickPoint, pickedPoint;
    LLPOINT midpt, pickPointLL;
    int minRef = 0;
    int nPicked = 0;
    NSString * minFid = @"";
    NSString * minPlatID = @"";
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    sqlite3_stmt *statement = NULL;
    
    pickPoint = DBoundsMid(platlonBounds);
    midpt.lon = pickPoint.x;
    midpt.lat = pickPoint.y;
    pickPointLL = midpt;
    dbounds bnds = [CRAPI.sharedInstance getPickApBoundsAtPoint:&midpt];
    if ([self openSLTIndex])
    {
        NSString *query = [NSString stringWithFormat:@"SELECT SHP.id FROM SHP,SHP_index WHERE SHP.id=SHP_index.id AND maxX>=%f AND minX<=%f AND maxY>=%f AND minY<=%f",
                           platlonBounds->xmn, platlonBounds->xmx, platlonBounds->ymn, platlonBounds->ymx];
        
        SQLOK(__FILE__,__LINE__,SQLitePrepare(_database, query.UTF8String, -1, &statement, 0), _database);
        
        while ([self continueProcessing] && sqlite3_step(statement) == SQLITE_ROW)
        {
            int irec = sqlite3_column_int(statement,0);
            
            SHPObject *psCShape = SHPReadObject (_hSHP, irec );
            MNMXCORD SHPBounds;
            SHPBounds.xmn = psCShape->dfXMin;
            SHPBounds.xmx = psCShape->dfXMax;
            SHPBounds.ymn = psCShape->dfYMin;
            SHPBounds.ymx = psCShape->dfYMax;
            _dc.refno = irec;
            if (BoundsInBounds (&SHPBounds,platlonBounds,1))
            {
                
                switch (psCShape->nSHPType)
                {
                    case SHPT_POINT:
                    case SHPT_POINTZ:
                    case SHPT_POINTM:
                    {
                        DPOINT pt, llpt;
                        pt.x = psCShape->padfX[0];
                        pt.y = psCShape->padfY[0];
                        llpt = pt;
                        pt = TranDPOINTP(&pt, _pTranLLtoView);
                        int iField, fieldWidth, nDecimals;
                        char fieldName[32];
                        switch (_dc.elementType)
                        {
                            case Hydrant:
                            {
                                iField = DBFGetFieldIndex(_hDBF, "Model");
                                if (iField >= 0)
                                {
                                    DBFGetFieldInfo(_hDBF,iField,
                                                    fieldName, &fieldWidth, &nDecimals );
                                    const char * cModel = DBFReadStringAttribute( _hDBF,irec,iField );
                                    if (!strcasecmp (cModel,"Single Pumper"))
                                        _dc.pointSymbol = TriangleSym;
                                    else if (!strcasecmp (cModel,"Double Pumper"))
                                        _dc.pointSymbol = SquareSym;
                                    else _dc.pointSymbol = Star1Sym;
                                }
                                iField = DBFGetFieldIndex(_hDBF, "Nozzle");
                                if (iField >= 0)
                                {
                                    DBFGetFieldInfo(_hDBF,iField,
                                                    fieldName, &fieldWidth, &nDecimals );
                                    const char * cNozzle = DBFReadStringAttribute( _hDBF,irec,iField );
                                    _dc.string2 = [NSString stringWithUTF8String:cNozzle];
                                }
                            }
                                break;
                            case FiberPoints:
                            {
                                _dc.pointSymbol = Star1Sym;
                                iField = DBFGetFieldIndex(_hDBF, "TYPE_OF_ST");
                                if (iField >= 0)
                                {
                                    DBFGetFieldInfo(_hDBF,iField,
                                                    fieldName, &fieldWidth, &nDecimals );
                                    const char * cType = DBFReadStringAttribute( _hDBF,irec,iField );
                                    _dc.string2 = [NSString stringWithUTF8String:cType];
                                }
                            }
                                break;
                                
                            case SanitaryManhole:
                                if (hlist)
                                {
                                    if (findClosestPointll (&llpt,&minpt,&mind,&pickPoint))
                                    {
                                        minRef = (int)_dc.refno;
                                        minPlatID = _dc.string2;
                                        PickedItem *pi = [PickedItem new];
                                        pi.refno = (int)_dc.refno;
                                        pi.identifier = [NSString stringWithFormat:@"SanMH:%i",minRef];
                                        pi.itemType = _dc.elementType;
                                        pi.pickedPoint = llpt;
                                        pi.distance = mind;
                                        [hlist addObject:pi];
                                    }
                                    
                                }
                                break;
                                
                            default:
                                break;
                        }
                        if ([themes setDisplayCharacteristics:_dc
                                                    displayID:_processingID
                                                 compareClass:nil] != DO_NOT_DISPLAY_ITEM)
                        {
                            if (hlist)
                            {
                                
                            }
                            else
                                [self drawPoint:context
                                        atPoint:&pt
                                    usingSymbol:_dc.pointSymbol
                                      withColor:_dc.fillColor.CGColor
                                        andSize:(_dc.size * _sizeFactor *[UIScreen mainScreen].nativeScale)];
                        }
                    }
                        break;
                        
                    default:
                    {
                        int fieldWidth, nDecimals, iField;
                        char fieldName[32];
                        double lineWidthFactor = 8*_widthFactor;
                        switch (_dc.elementType)
                        {
                            case StormMain:
                            {
                                _dc.width = 3;
                                iField = DBFGetFieldIndex(_hDBF, "DIAMETER");
                                if (iField >= 0)
                                {
                                    DBFGetFieldInfo(_hDBF,iField,
                                                    fieldName, &fieldWidth, &nDecimals );
                                    _dc.width = max (DBFReadDoubleAttribute( _hDBF,irec,iField )/lineWidthFactor,2);
                                }
                                iField = DBFGetFieldIndex(_hDBF, "Material");
                                if (iField >= 0)
                                {
                                    DBFGetFieldInfo(_hDBF,iField,
                                                    fieldName, &fieldWidth, &nDecimals );
                                    const char * cMaterial = DBFReadStringAttribute( _hDBF,irec,iField );
                                    _dc.string2 = [NSString stringWithUTF8String:cMaterial];
                                }
                            }
                                break;
                            case SanitaryMain:
                            {
                                NSString * fromMH=@"";
                                _dc.width = 3;
                                iField = DBFGetFieldIndex(_hDBF, "DIAMETER");
                                if (iField >= 0)
                                {
                                    DBFGetFieldInfo(_hDBF,iField,
                                                    fieldName, &fieldWidth, &nDecimals );
                                    _dc.width = max (DBFReadDoubleAttribute( _hDBF,irec,iField )/lineWidthFactor,2);
                                }
                                iField = DBFGetFieldIndex(_hDBF, "Material");
                                if (iField >= 0)
                                {
                                    DBFGetFieldInfo(_hDBF,iField,
                                                    fieldName, &fieldWidth, &nDecimals );
                                    const char * cMaterial = DBFReadStringAttribute( _hDBF,irec,iField );
                                    _dc.string2 = [NSString stringWithUTF8String:cMaterial];
                                }
                                iField = DBFGetFieldIndex(_hDBF, "FROMMH");
                                if (iField >= 0)
                                {
                                    DBFGetFieldInfo(_hDBF,iField,
                                                    fieldName, &fieldWidth, &nDecimals );
                                    const char * from = DBFReadStringAttribute( _hDBF,irec,iField );
                                    fromMH = [NSString stringWithUTF8String:from];
                                }
                                iField = DBFGetFieldIndex(_hDBF, "TOMH");
                                if (iField >= 0)
                                {
                                    DBFGetFieldInfo(_hDBF,iField,
                                                    fieldName, &fieldWidth, &nDecimals );
                                    const char * to = DBFReadStringAttribute( _hDBF,irec,iField );
                                    _dc.string2 = [NSString stringWithFormat:@"%@-%s",fromMH,to];
                                }
                            }
                                break;
                            case SanitaryManhole:
                            {
                                _dc.width = 3;
                                iField = DBFGetFieldIndex(_hDBF, "DIAMETER");
                                if (iField >= 0)
                                {
                                    DBFGetFieldInfo(_hDBF,iField,
                                                    fieldName, &fieldWidth, &nDecimals );
                                    _dc.width = max (DBFReadDoubleAttribute( _hDBF,irec,iField )/lineWidthFactor,2);
                                }
                                iField = DBFGetFieldIndex(_hDBF, "Material");
                                if (iField >= 0)
                                {
                                    DBFGetFieldInfo(_hDBF,iField,
                                                    fieldName, &fieldWidth, &nDecimals );
                                    const char * cMaterial = DBFReadStringAttribute( _hDBF,irec,iField );
                                    _dc.string2 = [NSString stringWithUTF8String:cMaterial];
                                }
                            }
                                break;
                            case WaterMain:
                            {
                                iField = DBFGetFieldIndex(_hDBF, "DIAMETER");
                                if (iField >= 0)
                                {
                                    DBFGetFieldInfo(_hDBF,iField,
                                                    fieldName, &fieldWidth, &nDecimals );
                                    _dc.width = DBFReadDoubleAttribute( _hDBF,irec,iField )/lineWidthFactor;
                                }
                                iField = DBFGetFieldIndex(_hDBF, "Material");
                                if (iField >= 0)
                                {
                                    DBFGetFieldInfo(_hDBF,iField,
                                                    fieldName, &fieldWidth, &nDecimals );
                                    const char * cMaterial = DBFReadStringAttribute( _hDBF,irec,iField );
                                    _dc.string2 = [NSString stringWithUTF8String:cMaterial];
                                }
                            }
                                break;
                            case FiberLines:
                            {
                                iField = DBFGetFieldIndex(_hDBF, "Strands");
                                if (iField >= 0)
                                {
                                    DBFGetFieldInfo(_hDBF,iField,
                                                    fieldName, &fieldWidth, &nDecimals );
                                    double segments = DBFReadDoubleAttribute( _hDBF,irec,iField );
                                    int iSegments = segments;
                                    _dc.UCR = iSegments;
                                    _dc.width = iSegments/lineWidthFactor;
                                }
                                
                            }
                                break;
                            case PDFBounds:
                            {
                                iField = DBFGetFieldIndex(_hDBF, "UDI");
                                
                                if (iField >= 0)
                                {
                                    DBFGetFieldInfo(_hDBF,iField, fieldName, &fieldWidth, &nDecimals );
                                    const char *cUDI = DBFReadStringAttribute(_hDBF,irec,iField);
                                    _dc.string2 = [NSString stringWithUTF8String:cUDI];
                                    
                                    if (_dc.refno == CRAPI.sharedInstance.showPlats)
                                        _dc.fillColor = UIColor.grayColor;
                                    
                                    else
                                    {
                                        _dc.fillColor = [NVColor randomColorFromArray:NVColor.pastelColors
                                                                            forString:_dc.string2];
                                    }
                                }
                            }
                                break;
                                
                            case ParcelBoundary:
                            {
                                iField = DBFGetFieldIndex(_hDBF, "TXNAME");
                                
                                if (iField >= 0)
                                {
                                    DBFGetFieldInfo(_hDBF,iField, fieldName, &fieldWidth, &nDecimals );
                                    const char *cUDI = DBFReadStringAttribute(_hDBF,irec,iField);
                                    _dc.string2 = [NSString stringWithUTF8String:cUDI];
                                    
                                    _dc.fillColor = [NVColor randomColorFromArray:NVColor.pastelColors
                                                                        forString:_dc.string2];
                                }
                            }
                                break;
                                
                            case Ownership:
                            {
                                iField = DBFGetFieldIndex(_hDBF, "OWNER_DESC");
                                
                                if (iField >= 0)
                                {
                                    DBFGetFieldInfo(_hDBF,iField, fieldName, &fieldWidth, &nDecimals );
                                    const char *cUDI = DBFReadStringAttribute(_hDBF,irec,iField);
                                    _dc.string2 = [NSString stringWithUTF8String:cUDI];
                                    
                                    _dc.fillColor = [NVColor randomColorFromArray:NVColor.pastelColors
                                                                        forString:_dc.string2];
                                }
                            }
                                break;
                                
                            default:
                                break;
                        }
                        
                        if ([themes setDisplayCharacteristics:_dc
                                                    displayID:_processingID
                                                 compareClass:nil] != DO_NOT_DISPLAY_ITEM)
                        {
                            if (_dc.elementType == PDFBounds)
                            {
                                LPDPOINT llpoints = malloc(psCShape->nVertices * sizeof(DPOINT) + 4);
                                
                                
                                for (int i = 0; i < psCShape->nVertices; i++)
                                {
                                    llpoints[i].x = psCShape->padfX[i];
                                    llpoints[i].y = psCShape->padfY[i];
                                    llpoints[i] = TranDPOINTP(&llpoints[i], _pTranLLtoView);
                                }
                                if (hlist)
                                {
                                    if (POINT_IN_AREAD(pickPoint, psCShape->nVertices, llpoints, 1, 0, 0, 0))
                                    {
                                        for (int i = 0; i < psCShape->nVertices; i++)
                                        {
                                            if (findClosestPointll (&llpoints[i],&minpt,&mind,&pickPoint))
                                            {
                                                minRef = (int)_dc.refno;
                                                minPlatID = _dc.string2;
                                                PickedItem *pi = [PickedItem new];
                                                pi.refno = (int)_dc.refno;
                                                pi.identifier = minPlatID;
                                                pi.itemType = _dc.elementType;
                                                pi.pickedPoint = llpoints[i];
                                                pi.distance = mind;
                                                [hlist addObject:pi];
                                            }
                                        }
                                    }
                                    
                                }
                                else
                                {
                                    [self fillArea:context nPoints:psCShape->nVertices
                                            points:llpoints
                                         withColor:_dc.fillColor.CGColor];
                                }
                                free (llpoints);
                                
                            }
                            else if (_dc.elementType == ParcelBoundary || _dc.elementType == Ownership)
                            {
                                CGColorRef color = _dc.fillColor.CGColor;
                                //if (_dc.refno == 20818)
                                //    color = UIColor.blackColor.CGColor;
                                LPDPOINT llpoints = malloc((psCShape->nVertices + psCShape->nParts) * sizeof(DPOINT) + 4);
                                
                                int startNextLoop = -1;
                                int np = 0;
                                int iPart = 1;
                                if (psCShape->nParts > 1)
                                    startNextLoop = psCShape->panPartStart[1];
                                for (int i = 0; i < psCShape->nVertices; i++)
                                {
                                    if (i == startNextLoop)
                                    {
                                        llpoints[np++] = llpoints[0];
                                        if (++iPart < psCShape->nParts)
                                            startNextLoop = psCShape->panPartStart[iPart];
                                        else
                                            startNextLoop = -1;
                                    }
                                    llpoints[np].x = psCShape->padfX[i];
                                    llpoints[np].y = psCShape->padfY[i];
                                    llpoints[np] = TranDPOINTP(&llpoints[np], _pTranLLtoView);
                                    np++;
                                    
                                }
                                if (psCShape->nParts > 1)
                                    llpoints[np++] = llpoints[0];
                                [self fillArea:context nPoints:np
                                        points:llpoints
                                     withColor:color];
                                if (_zoom > 13)
                                {
                                    NSString * text = _dc.string2;
                                    if (text.length)
                                    {
                                        UIColor *textColor = UIColor.redColor;
                                        CGFloat fontSize = 32.0 * screenScale;
                                        //LPSTR pTextValue[MAX_NVM_TEXT_FIELDS];
                                        
                                        CGFloat minFontSize = fontSize / 3;
                                        //if (nTextFields < 2)
                                        //    minFontSize = 6 * screenScale;
                                        for (int iloop = 0;iloop < psCShape->nParts;iloop++)
                                        {
                                            int istartLoop = psCShape->panPartStart[iloop] + iloop;
                                            int npInLoop;
                                            if (iloop+1 < psCShape->nParts)
                                                npInLoop = psCShape->panPartStart[iloop+1] - psCShape->panPartStart[iloop];
                                            else
                                                npInLoop = psCShape->nVertices - psCShape->panPartStart[iloop];
                                            if (ShowTextInLoop (&llpoints[istartLoop],npInLoop,pvbounds))
                                            {
                                                BOOL st = [NVTextDrawing drawText:text
                                                                        inContext:context
                                                                    withinPolygon:&llpoints[istartLoop]
                                                                    withNumPoints:npInLoop
                                                                      andNumLoops:1
                                                                          loopLen:psCShape->panPartStart
                                                                     withinBounds:pvbounds
                                                                         fontSize:fontSize
                                                                      minFontSize:minFontSize
                                                                        textColor:textColor
                                                                      shadowColor:nil
                                                                     processingID:_processingID];
                                            }
                                        }
                                    }
                                }
                                free (llpoints);
                            }
                            else
                            {
                                if (hlist)
                                {
                                    LPDPOINT llpoints = malloc(psCShape->nVertices * sizeof(DPOINT) + 4);
                                    
                                    for (int i = 0; i < psCShape->nVertices; i++)
                                    {
                                        llpoints[i].x = psCShape->padfX[i];
                                        llpoints[i].y = psCShape->padfY[i];
                                        llpoints[i] = TranDPOINTP(&llpoints[i], _pTranLLtoView);
                                    }
                                    if (PICK_POINT_ON_LINE(pickPoint, bnds, &pickedPoint, psCShape->nVertices, llpoints))
                                    {
                                        if (findClosestPointll (&pickedPoint, &minpt, &mind, &pickPoint))
                                        {
                                            nPicked++;
                                            minRef = (int)_dc.refno;
                                            minFid = _dc.string2;
                                            PickedItem *pi = [PickedItem new];
                                            pi.refno = (int)_dc.refno;
                                            pi.identifier = [NSString stringWithFormat:@"SanMain:%i",minRef];
                                            pi.data = _dc.string2;
                                            pi.itemType = _dc.elementType;
                                            pi.pickedPoint = minpt;
                                            pi.distance = mind;
                                            [hlist addObject:pi];
                                        }
                                    }
                                    free (llpoints);
                                    
                                }
                                else
                                {
                                    _dc.width = max (1,_dc.width);
                                    [self drawLine:context
                                           nPoints:psCShape->nVertices
                                            nLoops:psCShape->nParts
                                           partLen:psCShape->panPartStart
                                                 x:psCShape->padfX
                                                 y:psCShape->padfY
                                         withColor:_dc.penColor.CGColor
                                          andWidth:_dc.width*_widthFactor];
                                }
                            }
                        }
                    }
                }
            }
            SHPDestroyObject ( psCShape );
        }
        SQLOK(__FILE__,__LINE__,SQLiteFinalize(statement), _database);
        
    }
        [self close];

}

- (void)fillArea:(CGContextRef)context
           nPoints:(int)np
            points:(LPDPOINT)pPoints
         withColor:(CGColorRef)color
{
    //CGContextSetLineWidth(context, 3);
    CGContextMoveToPoint(context, pPoints[0].x, pPoints[0].y);
    
    for (int i = 1; i < np; i++)
        CGContextAddLineToPoint(context, pPoints[i].x, pPoints[i].y);
    
    CGContextAddLineToPoint(context, pPoints[0].x, pPoints[0].y);
    
    if (!CGContextIsPathEmpty(context))
    {
        CGContextSetStrokeColorWithColor(context,0);
        CGContextSetFillColorWithColor(context,color);
        //CGContextDrawPath(context, kCGPathFillStroke);
        CGContextDrawPath(context, kCGPathFill);
    }
}

- (void)drawLine:(CGContextRef)context
         nPoints:(int)np
          nLoops:(int)nLoops
         partLen:(int *)pPartIndex
               x:(double *)pX
               y:(double *)pY
       withColor:(CGColorRef)color
        andWidth:(CGFloat)width
{
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    width *= screenScale;
    CGContextSetLineWidth(context, width);
    CGContextSetLineJoin(context,kCGLineJoinRound);
    CGContextSetLineCap(context,kCGLineCapRound);
    LPDPOINT llpoints = malloc(np * sizeof(DPOINT) + 4);
    
    
    for (int i = 0; i < np; i++)
    {
        llpoints[i].x = pX[i];
        llpoints[i].y = pY[i];
        llpoints[i] = TranDPOINTP(&llpoints[i], _pTranLLtoView);
    }
    if (nLoops > 1)
    {
        int ip = 0;
        //int ii;
        
        for (int loop=0; loop < nLoops; loop++)
        {
            ip = pPartIndex[loop];
            CGContextMoveToPoint(context, llpoints[ip].x, llpoints[ip].y);
            ip++;
            //ii = pPartLen[loop];
            int lp = np - pPartIndex[loop];
            if (loop < nLoops - 1)
                lp = pPartIndex[loop+1] - pPartIndex[loop];
            for (int i = 1; i < lp; i++)
            {
                CGContextAddLineToPoint(context, llpoints[ip].x, llpoints[ip].y);
                ip++;
            }
            
            //if (loop)
            //    ip++;
            
            if (!CGContextIsPathEmpty(context))
            {
                CGContextSetStrokeColorWithColor(context,color);
                CGContextDrawPath(context, kCGPathStroke);
            }
        }
        
        //ii = ip;
    }
    
    else
    {
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path,0,llpoints[0].x, llpoints[0].y);
        
        for (int i = 1; i < np; i++)
            CGPathAddLineToPoint(path,0,llpoints[i].x, llpoints[i].y);
        
        if (!CGPathIsEmpty(path))
        {
            if (CRAPI.sharedInstance.GMTilesVisible)
            {
                CGContextSetLineWidth(context, width*2);
                CGContextSetStrokeColorWithColor(context,UIColor.whiteColor.CGColor);
                CGContextAddPath(context, path);
                CGContextDrawPath(context, kCGPathStroke);
                CGContextSetLineWidth(context, width);
            }
            CGContextAddPath(context, path);
            CGContextSetStrokeColorWithColor(context,color);
            CGContextDrawPath(context, kCGPathStroke);
        }
        CGPathRelease(path);
    }

}
- (void)drawPoint:(CGContextRef)context
               atPoint:(DPOINT *)pPoint
           usingSymbol:(PointSymbols)sym
             withColor:(CGColorRef)color
               andSize:(CGFloat)size

{
    [SymbolDictionary drawPointWithSymbol:context
                                       at:pPoint
                              usingSymbol:sym
                                     Size:size
                                fillColor:color
                                lineColor:0
                                lineWidth:size/8];
    
}

- (NSMutableArray*)pickPDFPlat:(LLPOINT *)pt

{
    NSMutableArray * highlightList = [[NSMutableArray alloc]init];
    int minRef = 0;
    dbounds bnds;
    MNMXCORD viewBounds;
    //CGFloat d;
    CGFloat pickap = 0.005;
    DPOINT p1, minpt;
    //DPOINT p2;
    NSString *minPlatID = [[NSString alloc] init];
    p1.x = pt->lon;
    p1.y = pt->lat;
    minpt = p1;
    bnds.xmn = (p1.x - pickap);
    bnds.xmx = (p1.x + pickap);
    bnds.ymn = (p1.y - pickap);
    bnds.ymx = (p1.y + pickap);
    _dc = [DisplayCharacteristics new];
    _dc.elementType = PDFBounds;
    
    [self processShape:nil
         highlightList:highlightList
              LLBounds:&bnds
            viewBounds:&viewBounds
                themes:nil];
    
    pt->lon = minpt.x;
    pt->lat = minpt.y;
    
    NSString *platFile = [NSString stringWithFormat:@"%@/SanPlats/%@.jpg",
                          _documentsDirectory, minPlatID];
    
    if (minRef)
        CRAPI.sharedInstance.currentPlatImagePath = platFile;
    return highlightList;
}

- (int)pickSHPPoint:(LLPOINT *)pt
                         ofType:(GraphicElementTypes)type
                  highlightList:(NSMutableArray*)highlightList
{
    int minRef = 0;
    dbounds bnds;
    //CGFloat d;
    CGFloat pickap = 0.005;
    DPOINT p1, minpt;
    //DPOINT p2;
    
    p1.x = pt->lon;
    p1.y = pt->lat;
    minpt = p1;
    bnds.xmn = (p1.x - pickap);
    bnds.xmx = (p1.x + pickap);
    bnds.ymn = (p1.y - pickap);
    bnds.ymx = (p1.y + pickap);
    _dc = [DisplayCharacteristics new];
    _dc.elementType = type;
    
    [self processShape:nil
         highlightList:highlightList
              LLBounds:&bnds
            viewBounds:&bnds
                themes:nil];
    
    pt->lon = minpt.x;
    pt->lat = minpt.y;
    
    return minRef;
}


@end
