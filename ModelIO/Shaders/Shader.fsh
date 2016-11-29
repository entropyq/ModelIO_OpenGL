//
//  Shader.fsh
//  ModelIO
//
//  Created by Matt Loflin on 11/28/16.
//  Copyright © 2016 Pair, Inc. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
