    clc
    tic
    fclose( 'all' )
    
%     f                   = 'E:\Dropbox\FutureScan_team\Recorded Data Files\Orlando Data\2013-11-15 Skew Tests\2013-11-15 skew tests.media\Fusion\2013-11-15 Skew Tests----11_15_2013 12_34 PM.gnet'  ;
%     f                   = 'E:\Dropbox\Olson Share\2014-03-03 and 2014-03-04 Coachella Backup\2014-03 Coachella GNET Backup\2014-03 coachella gnet backup.media\Fusion\2014-03-03 CVWD Irrigation Inspection----Monday, 2014-03-_1.gnet'
    [ f , p , ~ ]       = uigetfile( 'E:\Dropbox\Olson Share\2014-03-03 and 2014-03-04 Coachella Backup\2014-03 Coachella GNET Backup\2014-03 coachella gnet backup.media\Fusion\*.gnet' )
    [ pn , fn , en ]    = fileparts( fullfile( p , f ) )                                        ;
    self.fileName       = fullfile( p , f )                                                     ;
    if exist( [ p '\hd' ] , 'dir' )
        mkdir( [ p '\hd' ] )
    end
    file.hd         	= fullfile( [ pn '\hd' ] , [ fn '.hd' ] )        
    
    file.ipd            = fullfile( [ pn '\hd' ] , [ fn '.ipd' ] )                                     	
    self.motherFile     = self.fileName                                                         ;
    sessionInfo         = h5info( self.fileName , '/Session [1]' )                              ;
    numGroups           = numel( [ sessionInfo.Groups ] )                                       ;                          
    x                   = numGroups + 1                                                         ;
    self.groupInfo      = sessionInfo                                                           ;
    self.groupInfo( x ) = sessionInfo                                                           ;
    self.groupInfo( 1 ) = []                                                                    ;
    self.frameBreaks    = NaN                                                                   ;
    self.videoTimes     = NaN                                                                   ;
    distance            = h5read( self.fileName, '/Session [1]/Distance [1]/Data' )             ;
    self.distTimes      = NaN                                                                   ;
    
    for iGroups = 1 : numGroups
        
        if strfind( sessionInfo.Groups( iGroups ).Name , 'SSET' )   
                                                              disp( [ 'Video Found, ' sessionInfo.Groups( iGroups ).Name ] )                                ;
            self.groupInfo( iGroups )                       = h5info( self.fileName , sessionInfo.Groups( iGroups ).Name )                                  ;
            cell_names                                      = { self.groupInfo( iGroups ).Datasets(:).Name }                                                ;
            HD_num                                          = cellfun( @(x) strcmp( x , 'HD' ) , cell_names )                                               ;
            self.frameBreaks( end + 1 , 1 )                 = self.groupInfo( iGroups ).Datasets( HD_num ).Dataspace.Size + self.frameBreaks( end )         ;
            newVidTimes                                     = double( h5read( self.fileName, [ self.groupInfo( iGroups ).Name '/HD index' ] ) )             ;
            self.videoTimes                                 = [ self.videoTimes ; newVidTimes ]                                                             ;
            self.frameBreaks( isnan( self.frameBreaks ) )   = []                                                                                            ;
            self.videoTimes( isnan( self.videoTimes ) )     = []                                                                                            ;
            for iVidTimes               = 1 : numel( self.videoTimes )
                videoTime( iVidTimes )  = self.videoTimes( iVidTimes )                                                  ;                                      
                difference          	= abs( self.videoTimes( iVidTimes ) - distance.timestamp )                      ;
                closestMatch            = find( difference == min( difference ) , 1 , 'first' )                         ;
                vidDist( iVidTimes )  	= ( round( distance.value( closestMatch ) * 100 ) )                             ;
            end
            
            
            cum_ms                                          = round( ( self.videoTimes - min( self.videoTimes ) ) * 1e-4 )                                  ;
        end
    end

    emptyInfo                       = cellfun( @isempty , { self.groupInfo( : ).Name } )                    ;
    self.groupInfo( emptyInfo )     = []                                                      	            ;
    self.globalFrames               = numel( self.videoTimes )                                              ;
    self.serialDates                = ( self.videoTimes * 100e-9 ) / ( 60 * 60 * 24 ) + 367                 ;
    self.vecDates                   = datevec( self.serialDates )                                           ;
    ms                              = round( mod( self.vecDates( : , end ) , 1 ) * 1000 )                   ;
    msString                        = num2str( ms, '%.3d' )                                                 ;
    msString( : , 1 )               = []                                                                    ;
%     return
    self.underscoreDate	            = [ datestr( self.serialDates , 'yyyy_mm_dd_HH_MM_SS' ) msString ]      ; 
    self.colonDate                  =   datestr( self.serialDates , 'yyyy:mm:dd HH MM SS' )                 ;
    self.spaceDate                  = [ datestr( self.serialDates , 'yyyy_mm dd HH MM SS' ) msString ]      ;
    self.colonTime                  = [ datestr( self.serialDates , 'HH:MM:SS:'           ) msString ]      ;
                                      self.underscoreDate( 1 , : )
                                      self.colonDate( 1 , : )
    session                         = 1                                                                     ;
    frameInSession                  = 1                                                                     ;
                                      load intro.mat                                                        ;
   
    fid                             = fopen( file.hd , 'w' )                                                ;
                                      fwrite( fid , introString , 'uchar' )                                 ;
    
%     ipd_fid                         = fopen( [ pn '.' fn '.ipd' , 'w' )                                     ;
    ipd_fid                         = fopen( file.ipd , 'w' )                                               ;
    
    h_wait                          = waitbar( 0 , 'Writing Video Frames' )                                 ;
    for frameInSession = 1 : numel( self.videoTimes )
        if ~mod( frameInSession , 2000 )
            fclose( fid )
            extra_index             = idivide( frameInSession , int32( 2000 ) ) 
            new_filename            = [ file.hd( 1 : end-3 ) '_A' char( 64 + extra_index ) '.hd_' ]
                                      new_filename( end-10 : end )
                                      frameInSession
            fid                     = fopen( new_filename , 'w' )
            fwrite( fid , introString , 'uchar' )
        end
        waitbar( frameInSession / numel( self.videoTimes ) , h_wait , sprintf( 'Frame %d of %d' , frameInSession , numel( self.videoTimes ) ) )
        
        currentBinary   = cell2mat( h5read( self.fileName , [ self.groupInfo( session ).Name '/HD' ], ... % grab the binary jpeg frame
                                    frameInSession , 1 , 1 ) )                      ;
                                
        if currentBinary( end ) ~= uint8( 217 )     
%             disp( 'Extra byte Found' )                                              ;
            currentBinary( end ) = []                                               ;
        else
%             disp( 'No extra byte found' )                                           ;
        end
        
        currentSize     = numel( currentBinary )                                    ;
        fwrite( fid , currentSize , 'uint32' , 'l' )                                ;
        fwrite( fid , self.underscoreDate( frameInSession , : ) , 'uchar' )     	;
        fwrite( fid , 0 , 'uint8' )                                                 ;
        fwrite( fid , currentBinary , 'uint8' )                                     ;
        fwrite( fid , currentSize , 'uint32' , 'l' )                                ;
        frame           = frameInSession                                            ;
        ipd_string = [ sprintf( '%0.1d;%0.1d;' , vidDist( frame ) , cum_ms( frame ) ) self.colonTime( frame , : ) sprintf( '\n' ) ]         ;
        fwrite( ipd_fid , ipd_string )                                              ;
    end
    
disp( '----------------------------------' )
fclose( 'all' )
close all hidden
winopen( file.hd )
subplot( 2 , 1 , 1 )
plot( 1 : numel( distance.timestamp ) , distance.timestamp , 1 : numel( self.videoTimes ) , self.videoTimes )
legend( { 'Distance Timestamp' , 'Video TimeStamp' } )
hold on 
subplot( 2 , 1 , 2 )
plot( 1 : numel( vidDist ) , vidDist / 100 , 1 : numel( distance.value ) , distance.value )
legend( { 'Resulting Video Distance' , 'GNet Video Distance ' } )
toc
% dos( '"C:\Program Files (x86)\HxD\HxD.exe" "C:\Users\bclymer\Documents\GitHub\GNetToHD\test.hd"' )