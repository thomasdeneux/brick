function output = test_geometry(operationName,varargin)
switch operationName
    case "testCases"
        % Generate test cases :
        % two lines with points in column, x and y coordinates in lines
        % the last column is to store the expected result of doLinesIntersect
        
        % True cases 
        testCases = [[-1,1;0,0],[0,0;-1,1],[1;1]];
        testCases(:,:,end+1) = [[0,10;0,10],[2,16;2,4],[1;1]];
        testCases(:,:,end+1) = [[-2,0;0,0],[-2,-2;-2,2],[1;1]];
        testCases(:,:,end+1) = [[0,4;4,4],[4,4;0,8],[1;1]];
        testCases(:,:,end+1) = [[0,10;0,10],[6,2;6,2],[1;1]];
        testCases(:,:,end+1) = [[14,7;-2,7],[14,7;-2,7],[1;1]];
        testCases(:,:,end+1) = [[1,1;5,0],[10,0;1,1],[1;1]];
        testCases(:,:,end+1) = [[1,1;5,0],[10,0;1,1],[1;1]];

        % False cases
        testCases(:,:,end+1) = [[4,12;4,12],[6,8;8,10],[0;0]];
        testCases(:,:,end+1) = [[-4,-8;2,8],[0,-4;0,6],[0;0]];
        testCases(:,:,end+1) = [[0,0;0,2],[4,4;4,6],[0;0]];
        testCases(:,:,end+1) = [[0,0;0,2],[4,6;4,4],[0;0]];
        testCases(:,:,end+1) = [[-2,4;-2,4],[6,10;6,10],[0;0]];
        testCases(:,:,end+1) = [[0,2;0,2],[4,1;0,4],[0;0]];
        testCases(:,:,end+1) = [[2,8;2,2],[4,6;4,4],[0;0]];
        testCases(:,:,end+1) = [[4,4;2,4],[10,0;0,8],[0;0]];

        % copy initial cases and swap coordinates to have more cases. Each times it
        % multiply the number of cases by 2

        % swap x and y coordinates
        testCasesoriginalSize = size(testCases,3);
        testCases(:,:,end+1:end+size(testCases,3)) =testCases;
        testCases(1,:,testCasesoriginalSize+1:end)=testCases(2,:,1:testCasesoriginalSize);
        testCases(2,:,testCasesoriginalSize+1:end)=testCases(1,:,1:testCasesoriginalSize);

        % swap first and second segments
        testCasesoriginalSize = size(testCases,3);
        testCases(:,:,end+1:end+size(testCases,3)) = testCases;
        testCases(:,1:2,testCasesoriginalSize+1:end)=testCases(:,3:4,1:testCasesoriginalSize);
        testCases(:,3:4,testCasesoriginalSize+1:end)=testCases(:,1:2,1:testCasesoriginalSize);

        % swap first and second points
        testCasesoriginalSize = size(testCases,3);
        testCases(:,:,end+1:end+size(testCases,3)) = testCases;
        testCases(:,[1, 3],testCasesoriginalSize+1:end)=testCases(:,[2, 4],1:testCasesoriginalSize);
        testCases(:,[2, 4],testCasesoriginalSize+1:end)=testCases(:,[1, 3],1:testCasesoriginalSize);

        % swap first and second points of first segment
        testCasesoriginalSize = size(testCases,3);
        testCases(:,:,end+1:end+size(testCases,3)) = testCases;
        testCases(:,1,testCasesoriginalSize+1:end)=testCases(:,2,1:testCasesoriginalSize);
        testCases(:,2,testCasesoriginalSize+1:end)=testCases(:,1,1:testCasesoriginalSize);

        % swap first and second points of second segment
        testCasesoriginalSize = size(testCases,3);
        testCases(:,:,end+1:end+size(testCases,3)) = testCases;
        testCases(:,3,testCasesoriginalSize+1:end)=testCases(:,4,1:testCasesoriginalSize);
        testCases(:,4,testCasesoriginalSize+1:end)=testCases(:,3,1:testCasesoriginalSize);

        output = testCases;
        
    case "doSegmentsIntersect"
        
        testCases = test_geometry("testCases");

        sizeTestCases = size(testCases,3);
        results = "";
        anyError = "All test cases have the expected result";
        output = 1;
        for i = 1:sizeTestCases
           lines = testCases(:,:,i);
           result = fn_geometry("doSegmentsIntersect",lines(:,1:2),lines(:,3:4));
            % disp("test case:")
            % disp(i)
            % disp("result:")
            % disp(result)
            % disp("------------")
           if lines(1,5)
               expectedResult = "T";
               correspond = result;
           else
               expectedResult = "F";
               correspond = ~result;
           end

           results(i,1) = expectedResult+i;
           results(i,2) = result;
           if ~correspond
              correspond = "ERROR"; 
              anyError = "One or more test cases haven't the expected result";
              output = 0;
           end
           results(i,3) = correspond;
        end
        disp("Case number - Result -Correspond to expected result")
        disp(results)
        disp(anyError)
        
    case "getIntersectionOfTwoSegments"
        testCases = test_geometry("testCases");

        sizeTestCases = size(testCases,3);
        results = "";
        
        for i = 1:sizeTestCases
           lines = testCases(:,:,i);
           result = fn_geometry("getIntersectionOfTwoSegments",lines(:,1:2),lines(:,3:4));
            % disp("test case:")
            % disp(i)
            % disp("result:")
            % disp(result)
            % disp("------------")

           results(i,1) = i;
           results(i,2) = string(result(1,1));
           results(i,3) = string(result(2,1));
           results(i,4) = string(result(1,2));
           results(i,5) = string(result(2,2));
        end
        disp("Case number - Result")
        disp(results)
    otherwise
        disp("test_geometry is used with an unknown case: "+operationName)
end

end

