unit DUnit.EventBusTestU;
{

  Delphi DUnit Test Case
  ----------------------
  This unit contains a skeleton test case class generated by the Test Case Wizard.
  Modify the generated code to correctly setup and call the methods from the unit
  being tested.

}

interface

uses
  TestFramework, EventBus.Subscribers, System.SyncObjs, EventBus,
  System.SysUtils,
  EventBus.Poster, System.Classes, Generics.Collections, BOs;

type
  // Test methods for class TEventBus

  TestTEventBus = class(TTestCase)
  private
    FSubscriber: TSubscriber;
    procedure SetSubscriber(const Value: TSubscriber);
  public
    property Subscriber: TSubscriber read FSubscriber write SetSubscriber;
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestRegisterUnregister;
    procedure TestRegisterUnregisterMultipleSubscriber;
    procedure TestIsRegisteredTrueAfterRegister;
    procedure TestIsRegisteredFalseAfterUnregister;
    procedure TestSimplePost;
    procedure TestSimplePostOnBackgroundThread;
    procedure TestAsyncPost;
    procedure TestPostOnMainThread;
    procedure TestBackgroundPost;
    procedure TestBackgroundsPost;
  end;

implementation

procedure TestTEventBus.SetSubscriber(const Value: TSubscriber);
begin
  FSubscriber := Value;
end;

procedure TestTEventBus.SetUp;
begin
  FSubscriber := TSubscriber.Create;
end;

procedure TestTEventBus.TearDown;
begin
  if Assigned(FSubscriber) then
    FSubscriber.Free;
  FSubscriber := nil;
end;

procedure TestTEventBus.TestSimplePost;
var
  LEvent: TEventBusEvent;
  LMsg: string;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  LEvent := TEventBusEvent.Create;
  LMsg := 'TestSimplePost';
  LEvent.Msg := LMsg;
  TEventBus.GetDefault.Post(LEvent);
  CheckEqualsString(LMsg, Subscriber.LastEvent.Msg);
end;

procedure TestTEventBus.TestSimplePostOnBackgroundThread;
var
  LEvent: TEventBusEvent;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  LEvent := TEventBusEvent.Create;
  TThread.CreateAnonymousThread(
    procedure
    begin
      TEventBus.GetDefault.Post(LEvent);
    end).Start;
  // attend for max 5 seconds
  CheckTrue(TWaitResult.wrSignaled = Subscriber.Event.WaitFor(5000),
    'Timeout request');
  CheckNotEquals(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TestTEventBus.TestRegisterUnregister;
var
  LRaisedException: boolean;
begin
  LRaisedException := false;
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  try
    TEventBus.GetDefault.Unregister(Subscriber);
  except
    on E: Exception do
      LRaisedException := true;
  end;
  CheckFalse(LRaisedException);
end;

procedure TestTEventBus.TestRegisterUnregisterMultipleSubscriber;
var
  LRaisedException: boolean;
  LSubscriber: TSubscriberCopy;
  LEvent: TEventBusEvent;
  LMsg: string;
begin
  LSubscriber := TSubscriberCopy.Create;
  try
    TEventBus.GetDefault.RegisterSubscriber(Subscriber);
    TEventBus.GetDefault.RegisterSubscriber(LSubscriber);
    TEventBus.GetDefault.Unregister(Subscriber);
    LEvent := TEventBusEvent.Create;
    LMsg := 'TestSimplePost';
    LEvent.Msg := LMsg;
    TEventBus.GetDefault.Post(LEvent);
    CheckFalse(TEventBus.GetDefault.IsRegistered(Subscriber));
    CheckTrue(TEventBus.GetDefault.IsRegistered(LSubscriber));
    CheckEqualsString(LMsg, LSubscriber.LastEvent.Msg);
  finally
    LSubscriber.Free;
  end;
end;

procedure TestTEventBus.TestBackgroundPost;
var
  LEvent: TBackgroundEvent;
  LMsg: string;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  LEvent := TBackgroundEvent.Create;
  LMsg := 'TestBackgroundPost';
  LEvent.Msg := LMsg;
  TEventBus.GetDefault.Post(LEvent);
  // attend for max 5 seconds
  CheckTrue(TWaitResult.wrSignaled = Subscriber.Event.WaitFor(5000),
    'Timeout request');
  CheckEqualsString(LMsg, Subscriber.LastEvent.Msg);
  CheckNotEquals(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TestTEventBus.TestBackgroundsPost;
var
  LEvent: TBackgroundEvent;
  LMsg: string;
  I: Integer;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  for I := 0 to 10 do
  begin
    LEvent := TBackgroundEvent.Create;
    LMsg := 'TestBackgroundPost';
    LEvent.Msg := LMsg;
    LEvent.Count := I;
    TEventBus.GetDefault.Post(LEvent);
  end;
  // attend for max 2 seconds
  for I := 0 to 20 do
    TThread.Sleep(100);

  CheckEquals(10, TBackgroundEvent(Subscriber.LastEvent).Count);
end;

procedure TestTEventBus.TestIsRegisteredFalseAfterUnregister;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  CheckTrue(TEventBus.GetDefault.IsRegistered(Subscriber));
end;

procedure TestTEventBus.TestIsRegisteredTrueAfterRegister;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  TEventBus.GetDefault.Unregister(Subscriber);
  CheckFalse(TEventBus.GetDefault.IsRegistered(Subscriber));
end;

procedure TestTEventBus.TestPostOnMainThread;
var
  LEvent: TMainEvent;
  LMsg: string;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  LEvent := TMainEvent.Create;
  LMsg := 'TestPostOnMainThread';
  LEvent.Msg := LMsg;
  TEventBus.GetDefault.Post(LEvent);
  CheckEqualsString(LMsg, Subscriber.LastEvent.Msg);
  CheckEquals(MainThreadID, Subscriber.LastEventThreadID);
end;

procedure TestTEventBus.TestAsyncPost;
var
  LEvent: TAsyncEvent;
  LMsg: string;
begin
  TEventBus.GetDefault.RegisterSubscriber(Subscriber);
  LEvent := TAsyncEvent.Create;
  LMsg := 'TestAsyncPost';
  LEvent.Msg := LMsg;
  TEventBus.GetDefault.Post(LEvent);
  // attend for max 5 seconds
  CheckTrue(TWaitResult.wrSignaled = Subscriber.Event.WaitFor(5000),
    'Timeout request');
  CheckEqualsString(LMsg, Subscriber.LastEvent.Msg);
  CheckNotEquals(MainThreadID, Subscriber.LastEventThreadID);
end;

initialization

// Register any test cases with the test runner
RegisterTest(TestTEventBus.Suite);

end.
