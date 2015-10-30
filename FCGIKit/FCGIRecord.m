
- (NSString*)description
{
  return [NSString stringWithFormat:@"Version: %d, Type: %d, Request-ID: %d, ContentLength: %d, PaddingLength: %d", self.version, self.type, self.requestId, self.contentLength, self.paddingLength];
}

-(NSData*)headerProtocolData
{
  NSMutableData* protocolData = [NSMutableData dataWithCapacity:1024];
  [protocolData appendBytes:&version length:1];
  [protocolData appendBytes:&type length:1];
  
  uint16 bigEndianRequestId = EndianU16_NtoB(self.requestId);
  [protocolData appendBytes:&bigEndianRequestId length:2];
  
  uint16 bigEndianContentLength = EndianU16_NtoB(self.contentLength);
  [protocolData appendBytes:&bigEndianContentLength length:2];
  
  [protocolData appendBytes:&paddingLength length:1];

  unsigned char reserved = 0x00;
  [protocolData appendBytes:&reserved length:1];

  return protocolData;
}


@end
