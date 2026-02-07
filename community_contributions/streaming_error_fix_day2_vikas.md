# Issue description

I was trying to run day2 code solution Business Idea Generator. But the React UI application was failing at run time while trying process response stream from the OpenAI.


# Fix description

That error usually happens when the response stream is abruptly ended without a notification to the front-end application regarding end of stream, and the front-end application breaks anticipating for more data stream. 

As a solution, I updated event_stream() function and added try/finally block to return [DONE] at the end of stream response. Front-end application recognizes [DONE] and the connection is closed seamlessly instead terminating abruptly. This worked for me.

def event_stream():
        try:
            for chunk in stream:
                content = chunk.choices[0].delta.content
                if content:
                    
                    full_response.append(content)
                    lines = content.split("\n")
                    for line in lines[:-1]:
                        yield f"data: {line}\n\n"
                        yield "data:  \n"
                    yield f"data: {lines[-1]}\n\n"
        except Exception as e:
            logging.error(f"Error during streaming: {str(e)}")
            yield f"data: Error: {str(e)}\n\n"
        finally:
            yield "data: [DONE]\n\n"
            complete_response = ''.join(full_response)
            logging.info(f"Complete response: {repr(complete_response)}")
    return StreamingResponse(event_stream(), media_type="text/event-stream")
