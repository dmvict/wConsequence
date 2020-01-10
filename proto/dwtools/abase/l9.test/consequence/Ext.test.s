( function _Ext_test_s_( ) {

'use strict';

if( typeof module !== 'undefined' )
{

  let _ = require( '../../../Tools.s' );
  require( '../../l9/consequence/Consequence.s' );
  _.include( 'wTesting' );

  _.include( 'wLogger' );
  _.include( 'wAppBasic' );

}

let _ = _global_.wTools;
let fileProvider = _testerGlobal_.wTools.fileProvider;
let path = fileProvider.path;

// --
// context
// --

function onSuiteBegin()
{
  let self = this;

  self.suiteTempPath = path.pathDirTempOpen( path.join( __dirname, '../..'  ), 'ConsequenceExternal' );
  self.assetsOriginalSuitePath = path.join( __dirname, '_asset' );
}

//

function onSuiteEnd()
{
  let self = this;
  _.assert( _.strHas( self.suiteTempPath, '/ConsequenceExternal-' ) )
  path.pathDirTempClose( self.suiteTempPath );
}

//

function assetFor( test, ... args )
{
  let context = this;
  let a = test.assetFor( ... args );
  return a;
}

// --
// tests
// --

function uncaughtSyncErrorOnExit( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program );

  a.jsNonThrowing({ execPath : programPath })
  .then( ( op ) =>
  {
    test.notIdentical( op.exitCode, 0 );
    test.identical( _.strCount( op.output, 'uncaught error on termination' ), 2 );
    test.identical( _.strCount( op.output, 'uncaught error' ), 2 );
    test.identical( _.strCount( op.output, 'ncaught' ), 7 );
    test.identical( _.strCount( op.output, 'nhandled' ), 0 );
    test.identical( _.strCount( op.output, 'error1' ), 1 );
    return null;
  });

  return a.ready;

  function program()
  {
    var _ = require( toolsPath );
    _.include( 'wAppBasic' );
    let con = new _.Consequence();
    _.process.on( 'exit', () =>
    {
      debugger
      throw _.err( 'error1' );
    })
  }
}

uncaughtSyncErrorOnExit.description =
`
Uncaught synchronous error on temrination caught and handled
`

//

function uncaughtAsyncErrorOnExit( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program );

  a.jsNonThrowing({ execPath : programPath })
  .then( ( op ) =>
  {
    test.notIdentical( op.exitCode, 0 );
    test.identical( _.strCount( op.output, 'uncaught asynchronous error' ), 2 );
    test.identical( _.strCount( op.output, 'error1' ), 1 );
    return null;
  });

  return a.ready;

  function program()
  {
    var _ = require( toolsPath );
    _.include( 'wAppBasic' );
    let con = new _.Consequence();
    _.process.on( 'exit', () =>
    {
      debugger;
      con.error( 'error1' );
    })
  }
}

uncaughtAsyncErrorOnExit.description =
`
Uncaught synchronous error on temrination caught and handled
`

//

function uncaughtAsyncErrorConcurrentExecution( test )
{
  let context = this;
  let a = context.assetFor( test, false );
  let programPath = a.program( program );

  a.jsNonThrowing({ execPath : programPath })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( _.strCount( op.output, 'uncaught asynchronous error' ), 0 );
    return null;
  });

  return a.ready;

  function program()
  {
    var _ = require( toolsPath );
    _.include( 'wConsequence' );
    
    var con1 = _.time.out( 500, () => 
    { 
      throw 'Test error';
    })
    var con2 = _.time.out( 1000, () => 
    { 
      return null 
    })
    
    _.Consequence.AndKeep([ con1, con2 ])
    .catch(( err ) => 
    {
      _.errAttend( err );
      return null;
    })
  }
}

uncaughtAsyncErrorConcurrentExecution.experimental = 1;
uncaughtAsyncErrorConcurrentExecution.description =
`
First consequence gives error message after small delay.
Second consequence gives regular message after first consequence.
Third consequence waits until both consequences will be resolved.
Expected behaviour: Error about uncaught async error will not be thrown. Third consequence will catch error from first consequence.
`

//

function asyncStackWithTimeOut( test )
{
  let context = this;
  let visited = [];
  let a = context.assetFor( test, false );
  let programPath = a.program( program );

  /* */

  a.jsNonThrowing({ execPath : programPath })
  .then( ( op ) =>
  {
    test.notIdentical( op.exitCode, 0 );
    test.identical( _.strCount( op.output, 'Waiting for' ), 0 );
    test.identical( _.strCount( op.output, 'procedure::' ), 0 );
    test.identical( _.strCount( op.output, 'ncaught' ), 2 );
    test.identical( _.strCount( op.output, 'nhandled' ), 0 );
    test.identical( _.strCount( op.output, 'uncaught error' ), 2 );
    test.identical( _.strCount( op.output, /v1(.|\n|\r)*v2(.|\n|\r)*error1(.|\n|\r)*/mg ), 1 );
    test.identical( _.strCount( op.output, 'program.js:10' ), 1 );
    test.identical( _.strCount( op.output, 'program.js:13' ), 2 );
    return null;
  });

  /* */

  return a.ready;

  function program()
  {
    let _ = require( toolsPath );

    _.include( 'wConsequence' );
    _.include( 'wProcedure' );

    let t = 10;

    _.time.begin( t, () =>
    {
      console.log( 'v2' );
      throw _.err( 'error1' );
    });

    console.log( 'v1' );
  }

}

asyncStackWithTimeOut.timeOut = 60000;
asyncStackWithTimeOut.description =
`
- async stack presents
- async stack does not have duplicates
`

//

function asyncStackWithConsequence( test )
{
  let context = this;
  let visited = [];
  let a = context.assetFor( test, false );
  let programPath = a.program( program );

  /* */

  a.jsNonThrowing({ execPath : programPath })
  .then( ( op ) =>
  {
    test.notIdentical( op.exitCode, 0 );
    test.identical( _.strCount( op.output, 'Waiting for' ), 0 );
    test.identical( _.strCount( op.output, 'procedure::' ), 0 );
    test.identical( _.strCount( op.output, 'ncaught' ), 2 );
    test.identical( _.strCount( op.output, 'nhandled' ), 0 );
    test.identical( _.strCount( op.output, 'uncaught asynchronous error' ), 2 );
    test.identical( _.strCount( op.output, /v1(.|\n|\r)*v2(.|\n|\r)*error1(.|\n|\r)*/mg ), 1 );
    test.identical( _.strCount( op.output, 'program.js:11' ), 1 );
    test.identical( _.strCount( op.output, 'program.js:14' ), 2 );
    return null;
  });

  /* */

  return a.ready;

  function program()
  {
    let _ = require( toolsPath );

    _.include( 'wConsequence' );
    _.include( 'wProcedure' );

    let t = 10;
    let con = _.time.out( t );

    con.then( () =>
    {
      console.log( 'v2' );
      throw _.err( 'error1' );
    });

    console.log( 'v1' );
  }

}

asyncStackWithConsequence.timeOut = 60000;
asyncStackWithConsequence.description =
`
- async stack presents
- async stack does not have duplicates
`

//

function asyncStackInConsequenceTrivial( test )
{
  let context = this;
  let visited = [];
  let a = test.assetFor( false );
  let programPath = a.program( program );

  /* */

  a.jsNonThrowing({ execPath : programPath })
  .then( ( op ) =>
  {
    test.notIdentical( op.exitCode, 0 );
    test.identical( _.strCount( op.output, '- uncaught error -' ), 2 );
    test.identical( _.strCount( op.output, '= Source code from' ), 1 );
    test.identical( _.strCount( op.output, `program.js:9` ), 1 );
    test.identical( _.strCount( op.output, `at program` ), 1 );
    return null;
  });

  /* */

  return a.ready;

  function program()
  {
    let delay = 250;
    let _ = require( toolsPath );
    _.include( 'wFiles' );
    _.include( 'wConsequence' );

    var timeBefore = _.time.now();
    var t = _.time.outError( delay );
    t.finally( function( err, got )
    {
      if( err )
      _.errAttend( err );
      return null;
    })
    _.time.out( delay / 2, () => { t.error( _.errAttend( 'stop' ) ); return null; } );

    return t;
  }

}

asyncStackInConsequenceTrivial.timeOut = 30000;
asyncStackInConsequenceTrivial.description =
`
stack has async substack
`

//

function asyncStackInConsequenceThen( test )
{
  let context = this;
  let visited = [];
  let a = test.assetFor( false );
  let programPath = a.program( program );

  /* */

  a.jsNonThrowing({ execPath : programPath })
  .then( ( op ) =>
  {
    test.notIdentical( op.exitCode, 0 );
    test.identical( _.strCount( op.output, '- uncaught asynchronous error -' ), 2 );
    test.identical( _.strCount( op.output, '= Source code from' ), 1 );
    return null;
  });

  /* */

  return a.ready;

  function program()
  {
    let _ = require( toolsPath );
    _.include( 'wFiles' );
    _.include( 'wConsequence' );

    var con = _.Consequence()
    con.then( function callback1( arg )
    {
      console.log( 'sourcePath::callback1 ' + _.Procedure.ActiveProcedure._sourcePath );
      return 'callback1';
    })
    con.then( function callback2( arg )
    {
      console.log( 'sourcePath::callback2 ' + _.Procedure.ActiveProcedure._sourcePath );
      throw 'callback2';
      return 'callback2';
    })

    console.log( 'sourcePath::program ' + _.Procedure.ActiveProcedure._sourcePath );
    _.time.out( 100, function timeOut1()
    {
      console.log( 'sourcePath::timeout ' + _.Procedure.ActiveProcedure._sourcePath );
      con.take( 'timeout1' );
    });

  }

}

asyncStackInConsequenceThen.timeOut = 30000;
asyncStackInConsequenceThen.description =
`
each callback has its own stack
`

//

function tester( test )
{
  let context = this;
  let visited = [];
  let a = context.assetFor( test, false );

  let globals = Object.create( null );
  globals.toolsPath = a.path.nativize( a.path.join( __dirname, '../../../Tools.s' ) );
  globals.consequencePath = a.path.nativize( a.path.join( __dirname, '../../l9/consequence/Consequence.s' ) );

  let programPath = a.program({ program, globals });

  /* */

  a.jsNonThrowing({ execPath : programPath })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( _.strCount( op.output, 'Waiting for' ), 0 );
    test.identical( _.strCount( op.output, 'procedure::' ), 0 );
    test.identical( _.strCount( op.output, 'ncaught' ), 0 );
    test.identical( _.strCount( op.output, 'nhandled' ), 0 );
    test.identical( _.strCount( op.output, 'Passed test suites 1 / 1' ), 1 );
    return null;
  });

  /* */

  return a.ready;

  function program()
  {

    let _ = require( toolsPath );
    require( consequencePath );
    _.include( 'wTesting' );

    function routine1( test )
    {
      test.is( true );
    }

    var Self =
    {
      tests :
      {
        routine1,
      }
    }

    Self = wTestSuite( Self );
    wTester.test( Self.name );

  }

}

tester.timeOut = 60000;
tester.description =
`
- async stack presents
- async stack does not have duplicates
`

//

function timeLimit( test )
{
  let context = this;
  let visited = [];
  let a = context.assetFor( test, false );
  let programPath = a.program( program );

  /* */

  a.jsNonThrowing({ execPath : programPath })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( _.strCount( op.output, 'Waiting for' ), 0 );
    test.identical( _.strCount( op.output, 'procedure::' ), 0 );
    test.identical( _.strCount( op.output, 'ncaught' ), 0 );
    test.identical( _.strCount( op.output, 'nhandled' ), 0 );
    return null;
  });

  /* */

  return a.ready;

  function program()
  {
    let _ = require( toolsPath );
    let t = 25;
    _.include( 'wConsequence' );
    _.include( 'wProcedure' );
    var con = _.time.out( t*1 );
    con.timeLimit( t*6, () => _.time.out( t*3, 'a' ) );
    // _.procedure.terminationBegin();
  }

}

timeLimit.timeOut = 30000;
timeLimit.description =
`
- application does not have to wait for procedures
`

//

function timeLimitWaitingEnough( test )
{
  let context = this;
  let visited = [];
  let a = context.assetFor( test, false );
  let programPath = a.program( program );

  /* */

  a.jsNonThrowing({ execPath : programPath })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( _.strCount( op.output, 'ncaught' ), 0 );
    test.identical( _.strCount( op.output, 'nhandled' ), 0 );
    test.identical( _.strCount( op.output, 'Waiting for' ), 1 );
    test.identical( _.strCount( op.output, 'Waiting for 8 procedure(s)' ), 1 );
    test.identical( _.strCount( op.output, 'procedure::' ), 8 );
    test.identical( _.strCount( op.output, 'program.js:11' ), 6 );
    test.identical( _.strCount( op.output, 'program.js:14' ), 2 );
    test.identical( _.strCount( op.output, 'program.js:' ), 8 );
    test.identical( _.strCount( op.output, /v0(.|\n|\r)*v1(.|\n|\r)*v2(.|\n|\r)*v3(.|\n|\r)*v4/mg ), 1 );
    return null;
  });

  /* */

  return a.ready;

  function program()
  {
    let _ = require( toolsPath );
    let t = 1000;
    _.include( 'wConsequence' );
    _.include( 'wProcedure' );
    var con = _.time.out( t*1 );

    console.log( 'v0' );

    con.timeLimit( t*6, () =>
    {
      console.log( 'v2' );
      return _.time.out( t*3, () =>
      {
        console.log( 'v4' );
        return 'a';
      });
    });

    _.time.out( t*2, () =>
    {
      console.log( 'v3' );
      _.Procedure.TerminationPeriod = 1000;
      _.procedure.terminationBegin();
    });

    console.log( 'v1' );
  }

}

timeLimitWaitingEnough.timeOut = 60000;
timeLimitWaitingEnough.description =
`
- application should wait for procedures because of large time out of async routines
- limit is enough
`

//

function timeLimitWaitingNotEnough( test )
{
  let context = this;
  let visited = [];
  let a = context.assetFor( test, false );
  let programPath = a.program( program );

  /* */

  a.jsNonThrowing({ execPath : programPath })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( _.strCount( op.output, 'ncaught' ), 0 );
    test.identical( _.strCount( op.output, 'nhandled' ), 0 );
    test.identical( _.strCount( op.output, 'Waiting for' ), 1 );
    test.identical( _.strCount( op.output, 'Waiting for 3 procedure(s)' ), 1 );
    test.identical( _.strCount( op.output, 'procedure::' ), 3 );
    test.identical( _.strCount( op.output, 'program.js:12' ), 1 );
    test.identical( _.strCount( op.output, 'program.js:15' ), 2 );
    test.identical( _.strCount( op.output, 'program.js:' ), 3 );
    test.identical( _.strCount( op.output, /v0(.|\n|\r)*v1(.|\n|\r)*v2(.|\n|\r)*v3(.|\n|\r)*v4/mg ), 1 );
    return null;
  });

  /* */

  return a.ready;

  function program()
  {
    let _ = require( toolsPath );
    _.include( 'wConsequence' );
    _.include( 'wProcedure' );

    let t = 250;
    var con = _.time.out( t*1 );

    console.log( 'v0' );

    con.timeLimit( t*3, () =>
    {
      console.log( 'v2' );
      return _.time.out( t*6, () =>
      {
        console.log( 'v4' );
        return 'a';
      });
    });

    _.time.out( t*2, () =>
    {
      console.log( 'v3' );
      _.Procedure.TerminationPeriod = t*2;
      _.procedure.terminationBegin();
    });

    console.log( 'v1' );
  }

}

timeLimitWaitingNotEnough.timeOut = 60000;
timeLimitWaitingNotEnough.description =
`
- application should wait for procedures because of large time out of async routines
- limit is not enough
`

//

function timeCancelBefore( test )
{
  let context = this;
  let visited = [];
  let a = context.assetFor( test, false );
  let programPath = a.program( program );

  /* */

  a.jsNonThrowing({ execPath : programPath })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( _.strCount( op.output, 'ncaught' ), 0 );
    test.identical( _.strCount( op.output, 'nhandled' ), 0 );
    test.identical( _.strCount( op.output, 'Waiting for' ), 0 );
    test.identical( _.strCount( op.output, 'procedure::' ), 0 );
    test.identical( _.strCount( op.output, 'v1' ), 1 );
    test.identical( _.strCount( op.output, 'v2' ), 0 );
    return null;
  });

  /* */

  return a.ready;

  function program()
  {
    let _ = require( toolsPath );
    _.include( 'wConsequence' );
    _.include( 'wProcedure' );

    let t = 25;

    let timer = _.time.begin( t*2, () =>
    {
      console.log( 'v2' );
    });

    _.time.out( t, () => _.time.cancel( timer ) );

    console.log( 'v1' );

    _.Procedure.TerminationPeriod = 1000;
    _.procedure.terminationBegin();

    return _.time.out( t*3 );
  }

}

timeCancelBefore.timeOut = 60000;
timeCancelBefore.description =
`
- time cancel before time out leave no zombie
`

//

function timeCancelAfter( test )
{
  let context = this;
  let visited = [];
  let a = context.assetFor( test, false );
  let programPath = a.program( program );

  /* */

  a.jsNonThrowing({ execPath : programPath })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( _.strCount( op.output, 'ncaught' ), 0 );
    test.identical( _.strCount( op.output, 'nhandled' ), 0 );
    test.identical( _.strCount( op.output, 'Waiting for' ), 0 );
    test.identical( _.strCount( op.output, 'procedure::' ), 0 );
    test.identical( _.strCount( op.output, /v1(.|\n|\r)*v2(.|\n|\r)/mg ), 1 );
    return null;
  });

  /* */

  return a.ready;

  function program()
  {
    let _ = require( toolsPath );
    _.include( 'wConsequence' );
    _.include( 'wProcedure' );

    let t = 25;

    let timer = _.time.begin( t, () =>
    {
      console.log( 'v2' );
    });

    _.time.out( t*2, () => _.time.cancel( timer ) );

    console.log( 'v1' );

    _.Procedure.TerminationPeriod = 1000;
    _.procedure.terminationBegin();

    return _.time.out( t*3 );
  }

}

timeCancelAfter.timeOut = 60000;
timeCancelAfter.description =
`
- time cancel after time out leave no zombie
`

//

function timeOutExternalMessage( test )
{
  let context = this;
  let visited = [];
  let a = context.assetFor( test, false );
  let programPath = a.program( program );

  /* */

  a.jsNonThrowing({ execPath : programPath })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( _.strCount( op.output, 'Waiting for' ), 0 );
    test.identical( _.strCount( op.output, 'ncaught' ), 0 );
    test.identical( _.strCount( op.output, 'nhandled' ), 0 );

    test.identical( _.strCount( op.output, 'v1' ), 1 );
    test.identical( _.strCount( op.output, 'v2' ), 1 );
    test.identical( _.strCount( op.output, 'v3' ), 1 );
    test.identical( _.strCount( op.output, 'v4' ), 1 );
    test.identical( _.strCount( op.output, 'v5' ), 0 );
    test.identical( _.strCount( op.output, 'argumentsCount 0' ), 1 );
    test.identical( _.strCount( op.output, 'errorsCount 0' ), 1 );
    test.identical( _.strCount( op.output, 'competitorsCount 1' ), 1 );
    test.identical( _.strCount( op.output, /v1(.|\n|\r)*v2(.|\n|\r)*v3(.|\n|\r)*v4(.|\n|\r)*/mg ), 1 );

    return null;
  });

  /* */

  return a.ready;

  function program()
  {
    let _ = require( toolsPath );
    _.include( 'wProcedure' );
    _.include( 'wConsequence' );
    var t = 100;

    var con1 = _.time.out( t*2, () => 1 );

    console.log( 'v1' );
    _.time.out( t, function()
    {
      console.log( 'v2' );
      con1.take( 2 );
      con1.give( ( err, got ) =>
      {
        console.log( 'v3' );
      });
      con1.give( ( err, got ) =>
      {
        console.log( 'v4' );
      });
      con1.give( ( err, got ) =>
      {
        console.log( 'v5' );
      });
    })

    return _.time.out( t*5 ).then( () =>
    {
      console.log( 'v6' );
      console.log( 'argumentsCount', con1.argumentsCount() );
      console.log( 'errorsCount', con1.errorsCount() );
      console.log( 'competitorsCount', con1.competitorsCount() );
      con1.cancel();
      return null;
    });
  }

}

timeOutExternalMessage.timeOut = 60000;
timeOutExternalMessage.description =
`
- consequence of time out can get a message from outside of time out routine
`

//

function timeBegin( test )
{
  let context = this;
  let visited = [];
  let a = context.assetFor( test, false );
  let programPath = a.program( program );

  /* */

  a.jsNonThrowing({ execPath : programPath })
  .then( ( op ) =>
  {
    test.identical( op.exitCode, 0 );
    test.identical( _.strCount( op.output, 'ncaught' ), 0 );
    test.identical( _.strCount( op.output, 'nhandled' ), 0 );
    test.identical( _.strCount( op.output, 'Waiting for' ), 0 );
    test.identical( _.strCount( op.output, 'procedure::' ), 0 );
    test.identical( _.strCount( op.output, /v1(.|\n|\r)*v2(.|\n|\r)/mg ), 1 );
    return null;
  });

  /* */

  return a.ready;

  function program()
  {
    let _ = require( toolsPath );
    _.include( 'wConsequence' );
    _.include( 'wProcedure' );

    let t = 10;

    _.time.begin( t, () =>
    {
      console.log( 'v2' );
    });

    console.log( 'v1' );

    _.Procedure.TerminationPeriod = 1000;
    _.procedure.terminationBegin();

    _.time.out( t*2 );
  }

}

timeBegin.timeOut = 60000;
timeBegin.description =
`
- time begin leave no zombie procedures
`

// --
// declare
// --

var Self =
{

  name : 'Tools.base.Consequence.Ext',
  silencing : 1,

  onSuiteBegin,
  onSuiteEnd,

  context :
  {

    nameOfFile : 'Ext.test.s',
    suiteTempPath : null,
    assetsOriginalSuitePath : null,
    execJsPath : null,

    assetFor,

  },

  tests :
  {

    uncaughtSyncErrorOnExit,
    uncaughtAsyncErrorOnExit,
    uncaughtAsyncErrorConcurrentExecution,

    asyncStackWithTimeOut,
    asyncStackWithConsequence,
    asyncStackInConsequenceTrivial,
    asyncStackInConsequenceThen,

    tester,

    timeLimit,
    timeLimitWaitingEnough,
    timeLimitWaitingNotEnough,

    timeCancelBefore,
    timeCancelAfter,
    timeOutExternalMessage,
    timeBegin,

  }

}

Self = wTestSuite( Self );
if( typeof module !== 'undefined' && !module.parent )
wTester.test( Self.name );

})();
