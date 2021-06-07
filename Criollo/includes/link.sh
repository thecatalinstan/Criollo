#!/bin/bash

CRIOLLODIR=./Criollo
CRIOLLOSRCDIR=../Source
mkdir -p ${CRIOLLODIR}
rm -vrf ${CRIOLLODIR}/*.h

cp -v ${CRIOLLOSRCDIR}/CRTypes.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/CRApplication.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/CRServer.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/CRConnection.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/CRMessage.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/CRRequest.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/CRResponse.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/CRRequestRange.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/CRUploadedFile.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/CRMimeTypeHelper.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/CRStaticDirectoryManager.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/CRStaticFileManager.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/HTTP/CRHTTPServer.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/FCGI/CRFCGIServer.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/Routing/CRRouter.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/Routing/CRRouteController.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/Routing/CRNib.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/Routing/CRView.h ${CRIOLLODIR}/
cp -v ${CRIOLLOSRCDIR}/Routing/CRViewController.h ${CRIOLLODIR}/


COCOAASYNCSOCKETDIR=./CocoaAsyncSocket
COCOAASYNCSOCKETSRCDIR=../../Libraries/CocoaAsyncSocket/Source
mkdir -p ${COCOAASYNCSOCKETDIR}
rm -vrf ${COCOAASYNCSOCKETDIR}/*.h
cp -v  ${COCOAASYNCSOCKETSRCDIR}/GCD/GCDAsyncSocket.h  ${COCOAASYNCSOCKETDIR}/
