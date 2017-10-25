system2@lpim5192.ELFMISP1> column test format a1000
system2@lpim5192.ELFMISP1> set long 20000
system2@lpim5192.ELFMISP1> select dbms_metadata.get_ddl('TABLESPACE',tablespace_name )||';' as test from dba_tablespaces where tablespace_name in ('INV_IDX1');

TEST                                                                            
--------------------------------------------------------------------------------
                                                                                
  CREATE TABLESPACE "INV_IDX1" DATAFILE                                         
  '/u01/ORACLE/ELFMISP1/INV_IDX1.dbf' SIZE 2147483648,                          
  '/u02/ORACLE/ELFMISP1/INV_IDX2.dbf' SIZE 2147483648,                          
  '/u03/ORACLE/ELFMISP1/INV_IDX3.dbf' SIZE 2147483648,                          
  '/u11/ORACLE/ELFMISP1/INV_IDX4.dbf' SIZE 5242880000,                          
  '/u09/ORACLE/ELFMISP1/INV_IDX5.dbf' SIZE 3145728000,                          
  '/u08/ORACLE/ELFMISP1/INV_IDX6.dbf' SIZE 2147483648,                          
  '/u05/ORACLE/ELFMISP1/INV_IDX7.dbf' SIZE 1073741824,                          
  '/u13/ORACLE/ELFMISP1/INV_IDX8.dbf' SIZE 1073741824,                          
  '/u13/ORACLE/ELFMISP1/INV_IDX9.dbf' SIZE 4194304000,                          

TEST                                                                            
--------------------------------------------------------------------------------
  '/u15/ORACLE/ELFMISP1/INV_IDX10.dbf' SIZE 4194304000,                         
  '/u10/ORACLE/ELFMISP1/INV_IDX11.dbf' SIZE 10485760000,                        
  '/u17/ORACLE/ELFMISP1/INV_IDX12.dbf' SIZE 10485760000,                        
  '/u14/ORACLE/ELFMISP1/INV_IDX16.dbf' SIZE 5242880000,                         
  '/u18/ORACLE/ELFMISP1/INV_IDX13.dbf' SIZE 5242880000,                         
  '/u19/ORACLE/ELFMISP1/INV_IDX14.dbf' SIZE 10485760000,                        
  '/u19/ORACLE/ELFMISP1/INV_IDX15.dbf' SIZE 5242880000,                         
  '/u20/ORACLE/ELFMISP1/INV_IDX17.dbf [D[D[D[D[D[D[D_17.dbf' SIZE 5242880
000,                                                                            
  '/u14/ORACLE/ELFMISP1/INV_IDX18.dbf' SIZE 5242880000,                         
  '/u21/ORACLE/ELFMISP1/INV_IDX19.dbf' SIZE 5242880000,                         

TEST                                                                            
--------------------------------------------------------------------------------
  '/u21/ORACLE/ELFMISP1/IDX19.dbf' SIZE 5242880000,                             
  '/u22/ORACLE/ELFMISP1/INV_IDX19.dbf' SIZE 5242880000,                         
  '/u22/ORACLE/ELFMISP1/INV_IDX20.dbf' SIZE 5242880000,                         
  '/u24/ORACLE/ELFMISP1/INV_IDX21.dbf' SIZE 10485760000,                        
  '/u25/ORACLE/ELFMISP1/INV_IDX22.dbf' SIZE 10485760000,                        
  '/u25/ORACLE/ELFMISP1/INV_IDX23.dbf' SIZE 10485760000,                        
  '/u26/ORACLE/ELFMISP1/INV_IDX24.dbf' SIZE 10485760000,                        
  '/u26/ORACLE/ELFMISP1/INV_IDX25.dbf' SIZE 10485760000,                        
  '/u25/ORACLE/ELFMISP1/INV_IDX26.dbf' SIZE 10485760000,                        
  '/u27/ORACLE/ELFMISP1/INV_IDX26.dbf' SIZE 10485760000,                        
  '/u27/ORACLE/ELFMISP1/INV_IDX27.dbf' SIZE 10485760000,                        

TEST                                                                            
--------------------------------------------------------------------------------
  '/u27/ORACLE/ELFMISP1/INV_IDX28.dbf' SIZE 10485760000,                        
  '/u25/ORACLE/ELFMISP1/INV_IDX29.dbf' SIZE 10485760000,                        
  '/u28/ORACLE/ELFMISP1/INV_IDX29.dbf' SIZE 10485760000,                        
  '/u29/ORACLE/ELFMISP1/INV_IDX30.dbf' SIZE 20971520000,                        
  '/u29/ORACLE/ELFMISP1/INV_IDX31.dbf' SIZE 10485760000,                        
  '/u15/ORACLE/ELFMISP1/INV_IDX32.dbf' SIZE 10485760000,                        
  '/u27/ORACLE/ELFMISP1/INV_IDX32.dbf' SIZE 10485760000,                        
  '/u30/ORACLE/ELFMISP1/INV_IDX33.dbf' SIZE 21474836480,                        
  '/u30/ORACLE/ELFMISP1/INV_IDX34.dbf' SIZE 10737418240,                        
  '/u30/ORACLE/ELFMISP1/INV_IDX35.dbf' SIZE 21474836480,                        
  '/u30/ORACLE/ELFMISP1/INV_IDX36.dbf' SIZE 21474836480,                        

TEST                                                                            
--------------------------------------------------------------------------------
  '/u31/ORACLE/ELFMISP1/INV_IDX37.dbf' SIZE 21474836480,                        
  '/u31/ORACLE/ELFMISP1/INV_IDX38.dbf' SIZE 10485760000,                        
  '/u32/ORACLE/ELFMISP1/INV_IDX39.dbf' SIZE 10737418240,                        
  '/u31/ORACLE/ELFMISP1/INV_IDX40.dbf' SIZE 21474836480,                        
  '/u32/ORACLE/ELFMISP1/INV_IDX1.dbf' SIZE 21474836480,                         
  '/u32/ORACLE/ELFMISP1/INV_IDX1_41.dbf' SIZE 21474836480,                      
  '/u33/ORACLE/ELFMISP1/INV_IDX41.dbf' SIZE 10737418240,                        
  '/u31/ORACLE/ELFMISP1/INV_IDX42.dbf' SIZE 21474836480,                        
  '/u33/ORACLE/ELFMISP1/INV_IDX43.dbf' SIZE 21474836480,                        
  '/u34/ORACLE/ELFMISP1/INV_IDX44.dbf' SIZE 21474836480,                        
  '/u34/ORACLE/ELFMISP1/INV_IDX45.dbf' SIZE 21474836480,                        

TEST                                                                            
--------------------------------------------------------------------------------
  '/u29/ORACLE/ELFMISP1/INV_IDX46.dbf' SIZE 10989076480,                        
  '/u22/ORACLE/ELFMISP1/INV_IDX46.dbf' SIZE 106954752,                          
  '/u35/ORACLE/ELFMISP1/INV_IDX46.dbf' SIZE 21474836480,                        
  '/u35/ORACLE/ELFMISP1/INV_IDX47.dbf' SIZE 21474836480,                        
  '/u35/ORACLE/ELFMISP1/INV_IDX48.dbf' SIZE 21474836480,                        
  '/u36/ORACLE/ELFMISP1/INV_IDX49.dbf' SIZE 21474836480,                        
  '/u36/ORACLE/ELFMISP1/INV_IDX50.dbf' SIZE 15728640000,                        
  '/u37/ORACLE/ELFMISP1/INV_IDX51.dbf' SIZE 21474836480,                        
  '/u37/ORACLE/ELFMISP1/INV_IDX52.dbf' SIZE 21474836480,                        
  '/opt/oracle/product/11.2.0/db11203/dbs/MISSING00305' SIZE 10737418240,       
  '/u37/ORACLE/ELFMISP1/INV_IDX54.dbf' SIZE 10737418240                         

TEST                                                                            
--------------------------------------------------------------------------------
  LOGGING ONLINE PERMANENT BLOCKSIZE 8192                                       
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE DEFAULT                                  
 NOCOMPRESS  SEGMENT SPACE MANAGEMENT AUTO                                      
   ALTER DATABASE DATAFILE                                                      
  '/u01/ORACLE/ELFMISP1/INV_IDX1.dbf' RESIZE 12108955648                        
   ALTER DATABASE DATAFILE                                                      
  '/u02/ORACLE/ELFMISP1/INV_IDX2.dbf' RESIZE 7914651648                         
   ALTER DATABASE DATAFILE                                                      
  '/u03/ORACLE/ELFMISP1/INV_IDX3.dbf' RESIZE 8388608000                         
   ALTER DATABASE DATAFILE                                                      
  '/u11/ORACLE/ELFMISP1/INV_IDX4.dbf' RESIZE 12582912000                        

TEST                                                                            
--------------------------------------------------------------------------------
   ALTER DATABASE DATAFILE                                                      
  '/u09/ORACLE/ELFMISP1/INV_IDX5.dbf' RESIZE 5242880000                         
   ALTER DATABASE DATAFILE                                                      
  '/u08/ORACLE/ELFMISP1/INV_IDX6.dbf' RESIZE 10485760000                        
   ALTER DATABASE DATAFILE                                                      
  '/u05/ORACLE/ELFMISP1/INV_IDX7.dbf' RESIZE 1598029824                         
   ALTER DATABASE DATAFILE                                                      
  '/u13/ORACLE/ELFMISP1/INV_IDX8.dbf' RESIZE 10485760000                        
   ALTER DATABASE DATAFILE                                                      
  '/u13/ORACLE/ELFMISP1/INV_IDX9.dbf' RESIZE 10485760000                        
   ALTER DATABASE DATAFILE                                                      

TEST                                                                            
--------------------------------------------------------------------------------
  '/u15/ORACLE/ELFMISP1/INV_IDX10.dbf' RESIZE 10485760000                       
   ALTER DATABASE DATAFILE                                                      
  '/u17/ORACLE/ELFMISP1/INV_IDX12.dbf' RESIZE 12582912000                       
   ALTER DATABASE DATAFILE                                                      
  '/u18/ORACLE/ELFMISP1/INV_IDX13.dbf' RESIZE 10485760000                       
   ALTER DATABASE DATAFILE                                                      
  '/u19/ORACLE/ELFMISP1/INV_IDX15.dbf' RESIZE 12582912000                       
   ALTER DATABASE DATAFILE                                                      
  '/u27/ORACLE/ELFMISP1/INV_IDX26.dbf' RESIZE 21474836480                       
   ALTER DATABASE DATAFILE                                                      
  '/u27/ORACLE/ELFMISP1/INV_IDX27.dbf' RESIZE 21474836480                       

TEST                                                                            
--------------------------------------------------------------------------------
   ALTER DATABASE DATAFILE                                                      
  '/u27/ORACLE/ELFMISP1/INV_IDX28.dbf' RESIZE 21474836480                       
   ALTER DATABASE DATAFILE                                                      
  '/u28/ORACLE/ELFMISP1/INV_IDX29.dbf' RESIZE 21474836480                       
   ALTER DATABASE DATAFILE                                                      
  '/u29/ORACLE/ELFMISP1/INV_IDX31.dbf' RESIZE 21474836480                       
   ALTER DATABASE DATAFILE                                                      
  '/u15/ORACLE/ELFMISP1/INV_IDX32.dbf' RESIZE 12884901888                       
   ALTER DATABASE DATAFILE                                                      
  '/u27/ORACLE/ELFMISP1/INV_IDX32.dbf' RESIZE 21474836480                       
   ALTER DATABASE DATAFILE                                                      

TEST                                                                            
--------------------------------------------------------------------------------
  '/u30/ORACLE/ELFMISP1/INV_IDX34.dbf' RESIZE 21474836480                       
   ALTER DATABASE DATAFILE                                                      
  '/u31/ORACLE/ELFMISP1/INV_IDX38.dbf' RESIZE 21474836480                       
   ALTER DATABASE DATAFILE                                                      
  '/u32/ORACLE/ELFMISP1/INV_IDX39.dbf' RESIZE 21474836480                       
   ALTER DATABASE DATAFILE                                                      
  '/u33/ORACLE/ELFMISP1/INV_IDX41.dbf' RESIZE 21474836480                       
   ALTER DATABASE DATAFILE                                                      
  '/u29/ORACLE/ELFMISP1/INV_IDX46.dbf' RESIZE 21474836480                       
   ALTER DATABASE DATAFILE                                                      
  '/u22/ORACLE/ELFMISP1/INV_IDX46.dbf' RESIZE 21474836480                       

TEST                                                                            
--------------------------------------------------------------------------------
   ALTER DATABASE DATAFILE                                                      
  '/u36/ORACLE/ELFMISP1/INV_IDX50.dbf' RESIZE 21474836480                       
   ALTER DATABASE DATAFILE                                                      
  '/u37/ORACLE/ELFMISP1/INV_IDX54.dbf' RESIZE 21474836480;                      
                                                                                

system2@lpim5192.ELFMISP1> spool off
