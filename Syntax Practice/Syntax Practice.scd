/*  CPSC 431 Homework 2: Pset and Reading

This Pset is an evaluative one. We need to know if this set of problems is easy, medium, or hard.  (Of course, this is relative...)  To this end, the last "question" is your assessment of how difficult this homework was and how long it took to complete. The results are private and will be used to partially determine the level of difficulty of future Psets.

The reading for this week is the SuperCollider Book Chapter 5 on programming in SuperCollider. The chapter goes into more detail and covers more subjects than those I cover in the syntax classes.

Please submit this document to the Assignment page on Canvas being sure to rename it according to the guideline's naming convension: LASTNAME_431-HOMEWORK-2.scd


*/


/* Problem 1.

Use () and {} to define an expression that:

  • Defines two variables, one of which (variable one) is available to both structures and one (variable two) is only available within the inner structure { }.
  • Assigns integers to both variables.

When evaluated, the expression should:
  • multiply the variables
  • post the results to the post window.

*/

( // Your code here
{ // outer structure
	| multiplier |
	var variable1 = 1;
	{ // inner structure
		var variable2 = 2;
		"variable 1 is ".post;
		variable1.postln;

		"variable 2 is ".post;
		variable2.postln;

		"input multiplier is ".post;
		multiplier.postln;

		variable1 = variable1 * multiplier;
		"variable 1 after mutlipying becomes ".post;
		variable1.postln;

		variable2 = variable2 * multiplier;
		"varibale 2 after multiplying becomes ".post;
		variable2.postln;
	}.value
}.value(10)
)


/* Problem 2.

Write an expression that:
  • Randomly chooses eight integers between 0 and 10 (with no duplicates)
  • Uses the .add method to add them to an Array resulting in an array of size 8.
  • Assigns the array to an environmental variable.
  • Prints the variable to the post window

*/
// [“cat”, 5, 10.89].includesEqual(“cat”)
(  // Your code here
~environmentalArr;
{
	var tempArr = (0..10);
	var localArr = [];

	// it's faster to remove 2 from 11, instead of randomly getting 8 from 11
	while (
		{tempArr.size > 8},
		{tempArr.removeAt( rrand(0, tempArr.size - 1) )}
	);

	// Use .add method to copy all the randomly generated value
	for(0, tempArr.size - 1,
		{
			arg i;
			localArr = localArr ++ [tempArr[i]];
		}
	);

	// Assign the local array to environmental array
	~environmentalArr = localArr;
}.value;
~environmentalArr.postln;
)

/* Problem 3a.

Write an expression that:
   •  Generates one hundred float values between 0 and 1 rounded to the hundredth
   •  Converts those floats to the range 24-92 and rounds them to the nearest integer
   •  Removes duplicate numbers (resulting in an array with a size less than 100)
   •  Reorders the values such that they are ordered from highest to lowest
   •  Posts a multiline string with 1) the name of the results followed by the collection and 2) the size of the resulting collection
*/

(  // Your code here
{
	// float array of 0-1 rounded to the hundredth with size of 100
	var originalArr = Array.fill(100, {rrand(0.0, 1.0).round(0.01)});
	var mappedArr = [];

	"The array generated is ".post;
	originalArr.postln;

	// Convert to 24-92?
	for(0, originalArr.size - 1, {
		arg i;
		mappedArr = mappedArr ++ [ LinLin.ar(originalArr[i], 0.0, 1.0, 24.0, 92.0).asInteger ];
	});

	// Remove duplicate and reorder
	mappedArr = mappedArr.asSet.asSortedList.asArray;

	"The output array without duplicate is ".post;
	mappedArr.postln;
	"The variable name is mappedArr".postln;
	"The size is ".post;
	mappedArr.size.postln;

}.value;
)


/* Problem 3b.

Write an expression that:
Achieves an array with 100 unique float values (between 0 and 1) rounded to the hundredth decimal point, sorted high to low using the control structure 'while'. (As above, but do not follow the prescribed steps, just acheive the result as efficiently as possible.)

*/

(  // Your code here
{
	// float array of 0-1 rounded to the hundredth with size of 100
	var arr = Array.fill(100, {rrand(0.0, 1.0).round(0.01)});
	"The unsorted array is ".post;
	arr.postln;

    // Insertion Sort
	for(1, arr.size - 1,
		{
			arg i;
			var curr = arr[i];
			var j = i - 1;
			while (
				{ j >= 0 && { arr[j] > curr } },
				{
					arr[j + 1] = arr[j];
					j = j - 1;
				}
			);
			arr[j + 1] = curr;
		}
	);

	"The array after sorting is ".post;
	arr.postln;
}.value;
)


/*  Problem 4.

Write an expression that:
  • Uses the do Control Structure to fill an array with 5 octaves worth of a C major scale (in MIDI* numbers)
  • The numbers should start with 24 (Which is C1)

Below is an Environmental variable assigned to an Array (~array) to fill with the midi values.

~scale is assigned to a special kind of class, the Scale class.  When you iterate over ~scale you will see that it is already populated.

Expected Length: this can be coded in one-line using 4 messages (.thisIsAMessage) and 4 operations (this + thing).

Note: you will not be graded-down if your code is longer, is multiline, etc.  The above is to give you an idea of the amount of code required.

* all you need to know about MIDI for now is that MIDI numbers are integers between 0-127

*/

(
~array = [];
~scale = Scale.major;
{
	// Code your statement here
	var base = 24;
	for(0, 4, {
		for(0, ~scale.size - 1, {
			arg j;
			var curr = ~scale[j] + base;
			~array = ~array ++ [curr];
		});
		base = base + 12;
	});
}.value;

// Post your results
~array.postln;
)



// Output should be
// -> [ 24, 26, 28, 29, 31, 33, 35, 36, 38, 40, 41, 43, 45, 47, 48, 50, 52, 53, 55, 57, 59, 60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 77, 79, 81, 83 ]


/* Feedback: please answer the following two questions:


1. Pset difficulty (overall): range 0 (not difficult) to 5 (difficult)

Your answer: 2/5


2. Time it took you to complete all Psets (and excluding the reading):

Your answer: 3 hrs

Additional Comments (optional):

The description could be more accurate as it confused me a bit.

Overall it's great to have some practice like this to help get familiar with sc.

*/
