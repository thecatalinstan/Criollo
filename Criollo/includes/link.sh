#!/bin/bash

DIR=Criollo

rm -vrf ./${DIR}*.h

cp -v ../Source/CRTypes.h ${DIR}/
cp -v ../Source/CRApplication.h ${DIR}/
cp -v ../Source/CRServer.h ${DIR}/
cp -v ../Source/CRConnection.h ${DIR}/
cp -v ../Source/CRMessage.h ${DIR}/
cp -v ../Source/CRRequest.h ${DIR}/
cp -v ../Source/CRResponse.h ${DIR}/
cp -v ../Source/CRRequestRange.h ${DIR}/
cp -v ../Source/CRUploadedFile.h ${DIR}/
cp -v ../Source/CRMimeTypeHelper.h ${DIR}/
cp -v ../Source/CRStaticDirectoryManager.h ${DIR}/
cp -v ../Source/CRStaticFileManager.h ${DIR}/

cp -v ../Source/HTTP/CRHTTPServer.h ${DIR}/
cp -v ../Source/FCGI/CRFCGIServer.h ${DIR}/

cp -v ../Source/Routing/CRRouter.h ${DIR}/
cp -v ../Source/Routing/CRRouteController.h ${DIR}/
cp -v ../Source/Routing/CRNib.h ${DIR}/
cp -v ../Source/Routing/CRView.h ${DIR}/
cp -v ../Source/Routing/CRViewController.h ${DIR}/
