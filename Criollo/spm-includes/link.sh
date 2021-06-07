#!/bin/bash

rm -vrf ./*.h

cp -v ../Source/CRTypes.h .
cp -v ../Source/CRApplication.h .
cp -v ../Source/CRServer.h .
cp -v ../Source/CRConnection.h .
cp -v ../Source/CRMessage.h .
cp -v ../Source/CRRequest.h .
cp -v ../Source/CRResponse.h .
cp -v ../Source/CRRequestRange.h .
cp -v ../Source/CRUploadedFile.h .
cp -v ../Source/CRMimeTypeHelper.h .
cp -v ../Source/CRStaticDirectoryManager.h .
cp -v ../Source/CRStaticFileManager.h .

cp -v ../Source/HTTP/CRHTTPServer.h .
cp -v ../Source/FCGI/CRFCGIServer.h .

cp -v ../Source/Routing/CRRouter.h .
cp -v ../Source/Routing/CRRouteController.h .
cp -v ../Source/Routing/CRNib.h .
cp -v ../Source/Routing/CRView.h .
cp -v ../Source/Routing/CRViewController.h .
