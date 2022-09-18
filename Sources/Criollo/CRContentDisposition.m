//
//  CRContentDisposition.m
//  
//
//  Created by Cătălin Stan on 18/09/2022.
//

#import <Criollo/CRContentDisposition.h>

CRContentDisposition const CRContentDispositionInline = @"inline";
CRContentDisposition const CRContentDispositionAttachment = @"attachment";

CRContentDisposition CRContentDispositionFromString(NSString *contentDispositionName) {
    CRContentDisposition contentDisposition;
    if ([contentDispositionName isEqualToString:CRContentDispositionInline]) {
        contentDisposition = CRContentDispositionInline;
    } else if ([contentDispositionName isEqualToString:CRContentDispositionAttachment]) {
        contentDisposition = CRContentDispositionAttachment;
    }
    return contentDisposition;
}
