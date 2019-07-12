//
//  ViewController.m
//  PYNetwork
//
//  Created by wlpiaoyi on 2017/4/10.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//

#import "ViewController.h"
#import "PYNetwork.h"

@interface PYFormMutableDictionary<KeyType, ObjectType> : NSMutableDictionary<KeyType, ObjectType>

@end

@implementation PYFormMutableDictionary

@end


@interface ViewController ()
//@property (weak, nonatomic) IBOutlet PYAsyImageView *imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    PYXmlElement * xml = [[PYXmlElement alloc] init];
//    xml.elementName = @"elementName";
//    xml.attributes = @{@"attribute1":@"value"};
//    xml.string = @"string value";
    static PYNetwork * nw;
    nw = [PYNetwork new];
    nw.method = PYNET_HTTP_POST;//67765498860
    nw.url = @"https://log.snssdk.com/service/2/device_register/?tt_data=a&device_id=12345678901&is_activated=1&aid=1128";
   
    NSMutableDictionary * header =[[[@"ewogICJBY2NlcHQiIDogImFwcGxpY2F0aW9uXC9qc29uIiwKICAiQ29va2llIiA6ICJpbnN0YWxsX2lkPTcyMjA1NDE1NDc1OyBvZGluX3R0PTkzNjQ2Y2EwNWI5NmFhOGNkOGVjYjA5M2JhYzRjOWU5NDVlNmU3YjUyMzkyN2Y0OTJkZjk1NWM4OGY3MDU4NDE3YmEzNjlkMjQ5NWI3OWNiOGZkYjE5ZDUxNGRhMDE2ZWRkY2Y2YjIwZmIyMmQ1Y2Q4NjQ5MDQwMGQ1ZThkNDE4OyB0dHJlcT0xJGE5M2UwOTc2NjI3YWMxNjRlYmRjZWI1MWE0MzI4NDRmZWJkZGY0MTkiLAogICJDb25uZWN0aW9uIiA6ICJrZWVwLWFsaXZlIiwKICAiQ29udGVudC1UeXBlIiA6ICJhcHBsaWNhdGlvblwvb2N0ZXQtc3RyZWFtO3R0LWRhdGE9YSIsCiAgIlgtU1MtQ29va2llIiA6ICJpbnN0YWxsX2lkPTcyMjA1NDE1NDc1OyBvZGluX3R0PTkzNjQ2Y2EwNWI5NmFhOGNkOGVjYjA5M2JhYzRjOWU5NDVlNmU3YjUyMzkyN2Y0OTJkZjk1NWM4OGY3MDU4NDE3YmEzNjlkMjQ5NWI3OWNiOGZkYjE5ZDUxNGRhMDE2ZWRkY2Y2YjIwZmIyMmQ1Y2Q4NjQ5MDQwMGQ1ZThkNDE4OyB0dHJlcT0xJGE5M2UwOTc2NjI3YWMxNjRlYmRjZWI1MWE0MzI4NDRmZWJkZGY0MTkiLAogICJ0dC1yZXF1ZXN0LXRpbWUiIDogIjE1NTgwNzY5MjAzMTkiLAogICJVc2VyLUFnZW50IiA6ICJBd2VtZSA2LjIuMCBydjo2MjAwOSAoaVBob25lOyBpT1MgMTEuNC4xOyB6aF9DTikgQ3JvbmV0IiwKICAiYWlkIiA6ICIxMTI4Igp9" toDataForBase64] toDictionary] mutableCopy];
    NSData * httpBody = [@"dGMCBj3Yv+yerCAuru/+LTvoCRsHFqVnHThfMIN9hEE5Zq05zI5c9P2mdWbKd7K0FImuWFRi+/8Dvr3YR1q3Op41/Rn4xzrSR+AU7VPMMZ0vjlCMRhYESARyfgilK82wap6WzPJ0kY2WKnKqEjKfp600dmESQ8pSObxPe155eCZITujt4S9VyuXvC2bdcLvFMlMHij+jxDBfl9/7+PNVwOIRj2dgzO9mC+n4FzKhjVP6rjedurokt7MaiKyIFNBODGO8NY3hy5Zow0WtfX3yOTaEkV5geDKUIKvLeOnbad5AwMSVXQ/zuIP3jYq7rZmzyyebu83lFGCOnmmC6zrAr1RQ3f9eiyApMIylAxsG+Q6odjx2Lbg9zU+BLTcJqRyF9DZCHaYZWUwsYrcQG2W1eTEkSziZy1e2T/Gwg8jVH3bZ9Wt/zwiiQB0d8EJY+9PeiAX2r0/8qu9aaYHgpVTZtC5RczmxweAPzn5JKSWxFyO2vJ5HfH/CePhV+/lc6OWqR6zIdt+dVUd7DJ3kh69Hp08KbjnCGAbcgwtDVFabFaiSQ3eaamagBscRvjPrLdh5hLCGb0Y8BghUJn5jbzTkC+P2LzTBXUTlnSa4gImkBkGQbPNVJSCTd4k+N28L+Ikaf7sQnRQzNqUHwsSg2TP3ldBn4O7g7ypDzft7IOhOXEcNGvS2Vc3BCGQlJUPsR10M5Bnj1zJe6jPwbmpsvugHtstMdWkL9zouBShNnJxhEAVF09Urq8vluzJ9ZGIzlu1t9aaAnJh0TV4QNQxU9MCZ3W0CkwH/KVIkDfJ1wNLQwAHiqcSiIE3Scd2JOCNQD/4zXPH1ew==" toDataForBase64];
    header[@"X-SS-Cookie"] = header[@"Cookie"] = @"install_id=72205415475; odin_tt=93646ca05b96aa8cd8ecb093bac4c473625e6e7b5231234592df955c88f7058417ba369d2495b79cb8fdb19d514da016eddcf6b20fb22d5cd86490400d5e8d418; ttreq=1$a93e0976627ac164ebdceb51a1234567890df419";
    
    nw.heads = header;
    nw.params = httpBody;
    [nw setBlockComplete:^(id  _Nullable data, NSURLResponse * _Nullable response, PYNetwork * _Nonnull target) {
        NSLog(@"===================================================================");
        NSLog(@"%@",[data isKindOfClass:[NSData class]] ? [data toString] : [data description]);
        NSLog(@"===================================================================");
    }];
    [nw resume];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
